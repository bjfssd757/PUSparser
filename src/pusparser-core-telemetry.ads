package Pusparser.Core.Telemetry
  with SPARK_Mode
is
   Primary_Size   : constant Positive := 6;
   Sec_Fixed_Size : constant Positive := 7;

   type Byte is mod 2 ** 8;

   type Bits_1 is mod 2 ** 1;
   type Bits_2 is mod 2 ** 2;
   type Bits_3 is mod 2 ** 3;
   type Bits_4 is mod 2 ** 4;
   type Bits_8 is mod 2 ** 8;
   type Bits_11 is mod 2 ** 11;
   type Bits_14 is mod 2 ** 14;
   type Bits_16 is mod 2 ** 16;

   type Unsigned_16 is mod 2 ** 16;
   for Unsigned_16'Size use 16;

   type Unsigned_8 is mod 2 ** 8;
   for Unsigned_8'Size use 8;

   type Raw_Data is array (Positive range <>) of Unsigned_8;

   type Absolute_Time_Slice is record
      First : Positive;
      Last  : Positive;
   end record;

   type Primary_Header is record
      Packet_Version_Number : Bits_3;
      Packet_Type           : Bits_1;
      Secondary_Header_Flag : Bits_1;
      Apid                  : Bits_11;
      Sequence_Flags        : Bits_2;
      Packet_Sequence_Count : Bits_14;
      Packet_Data_Length    : Bits_16;
   end record;

   for Primary_Header use
     record
       Packet_Version_Number at 0 range 0 .. 2;
       Packet_Type           at 0 range 3 .. 3;
       Secondary_Header_Flag at 0 range 4 .. 4;
       Apid                  at 0 range 5 .. 15;
       Sequence_Flags        at 2 range 0 .. 1;
       Packet_Sequence_Count at 2 range 2 .. 15;
       Packet_Data_Length    at 4 range 0 .. 15;
     end record;

   type Secondary_Header is record
      Tm_Packet_Pus_Version_Number : Bits_4;
      Spacecraft_Time_Ref_Status   : Bits_4;
      Service_Type_Id              : Bits_8;
      Service_Subtype_Id           : Bits_8;
      Message_Type_Counter         : Bits_16;
      Destination_Id               : Bits_16;
      Time_Slice                   : Absolute_Time_Slice;
   end record;

   type User_Data_Type is record
      Packet_Error_Control : Unsigned_16;
   end record;

   type CCSDS_Space_Packet is record
      Primary   : Primary_Header;
      Secondary : Secondary_Header;
      User_Data : User_Data_Type;
   end record;

   function Get_CCSDS_Total_Length (Buffer : Raw_Data) return Positive
   is (7
       + Natural (Buffer (Buffer'First + 4)) * 256
       + Natural (Buffer (Buffer'First + 5)))
   with Pre => Buffer'Length >= 6;

   function Model_Get_Apid
     (Buffer : Raw_Data; Start_Ptr : Positive) return Bits_11
   is (Bits_11
         (((Bits_16 (Buffer (Start_Ptr)) * 256)
           + Bits_16 (Buffer (Start_Ptr + 1)))
          and 16#7FF#))
   with
     Ghost,
     Inline,
     Pre =>
       Start_Ptr < Integer'Last
       and then Start_Ptr in Buffer'Range
       and then Start_Ptr + 1 in Buffer'Range;

   procedure PUS_Deserialize
     (Buffer      : Raw_Data;
      Time_Length : Positive;
      Packet      : out CCSDS_Space_Packet;
      Success     : out Boolean)
   with
     Pre  =>
       Buffer'Length >= 6
       and then Buffer'Length >= Get_CCSDS_Total_Length (Buffer)
       and then Sec_Fixed_Size <= Integer'Last - Time_Length
       and then Primary_Size <= Integer'Last - Time_Length
       and then Buffer'Last <= Integer'Last - Time_Length,

     Post =>
       (if Success
        then
          (if Packet.Primary.Secondary_Header_Flag = 1
           then
             Packet.Secondary.Time_Slice.First >= Buffer'First
             and Packet.Secondary.Time_Slice.Last <= Buffer'Last
             and
               Packet.Secondary.Time_Slice.First
               <= Packet.Secondary.Time_Slice.Last)

          and

              Natural (Packet.Primary.Packet_Data_Length)
            = Get_CCSDS_Total_Length (Buffer) - Primary_Size - 1

          and

              Packet
              .Primary
              .Apid
            = Model_Get_Apid (Buffer, Buffer'First));
end Pusparser.Core.Telemetry;
