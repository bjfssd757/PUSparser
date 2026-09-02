package body Pusparser.Core.Telemetry
  with SPARK_Mode
is
   procedure PUS_Deserialize
     (Buffer      : Raw_Data;
      Time_Length : Positive;
      Packet      : out CCSDS_Space_Packet;
      Success     : out Boolean)
   is
      Current_Ptr            : Positive := Buffer'First;
      Word_1, Word_2, Word_3 : Bits_16;
   begin
      Packet :=
        (Primary   =>
           (Packet_Version_Number => 0,
            Packet_Type           => 0,
            Secondary_Header_Flag => 0,
            Apid                  => 0,
            Sequence_Flags        => 0,
            Packet_Sequence_Count => 0,
            Packet_Data_Length    => 0),
         Secondary =>
           (Tm_Packet_Pus_Version_Number => 0,
            Spacecraft_Time_Ref_Status   => 0,
            Service_Type_Id              => 0,
            Service_Subtype_Id           => 0,
            Message_Type_Counter         => 0,
            Destination_Id               => 0,
            Time_Slice                   => (First => 1, Last => 1)),
         User_Data => (Packet_Error_Control => 0));

      if Buffer'Length < Primary_Size then
         Success := False;
         return;
      end if;

      Word_1 :=
        Bits_16 (Buffer (Current_Ptr))
        * 256
        + Bits_16 (Buffer (Current_Ptr + 1));
      Word_2 :=
        Bits_16 (Buffer (Current_Ptr + 2))
        * 256
        + Bits_16 (Buffer (Current_Ptr + 3));
      Word_3 :=
        Bits_16 (Buffer (Current_Ptr + 4))
        * 256
        + Bits_16 (Buffer (Current_Ptr + 5));

      Packet.Primary.Packet_Version_Number :=
        Bits_3 ((Word_1 / 2 ** 13) and 16#7#);

      Packet.Primary.Packet_Type := Bits_1 ((Word_1 / 2 ** 12) and 16#1#);

      Packet.Primary.Secondary_Header_Flag :=
        Bits_1 ((Word_1 / 2 ** 11) and 16#1#);

      Packet.Primary.Apid := Bits_11 (Word_1 and 16#7FF#);

      Packet.Primary.Sequence_Flags := Bits_2 ((Word_2 / 2 ** 14) and 16#3#);

      Packet.Primary.Packet_Sequence_Count := Bits_14 (Word_2 and 16#3FFF#);

      Packet.Primary.Packet_Data_Length := Word_3;

      Current_Ptr := Current_Ptr + Primary_Size;

      if Packet.Primary.Secondary_Header_Flag = 1 then
         if Buffer'Last < Current_Ptr
           or else
             (Buffer'Last - Current_Ptr) + 1 < Sec_Fixed_Size + Time_Length
         then
            Success := False;
            return;
         end if;

         Packet.Secondary.Tm_Packet_Pus_Version_Number :=
           Bits_4 ((Buffer (Current_Ptr) / 2 ** 4) and 16#F#);

         Packet.Secondary.Spacecraft_Time_Ref_Status :=
           Bits_4 (Buffer (Current_Ptr) and 16#F#);

         Packet.Secondary.Service_Type_Id := Bits_8 (Buffer (Current_Ptr + 1));

         Packet.Secondary.Service_Subtype_Id :=
           Bits_8 (Buffer (Current_Ptr + 2));

         Packet.Secondary.Message_Type_Counter :=
           Bits_16 (Buffer (Current_Ptr + 3))
           * 256
           + Bits_16 (Buffer (Current_Ptr + 4));

         Packet.Secondary.Destination_Id :=
           Bits_16 (Buffer (Current_Ptr + 5))
           * 256
           + Bits_16 (Buffer (Current_Ptr + 6));

         Current_Ptr := Current_Ptr + Sec_Fixed_Size;

         Packet.Secondary.Time_Slice.First := Current_Ptr;
         Packet.Secondary.Time_Slice.Last := Current_Ptr + Time_Length - 1;

         pragma Assert (Packet.Secondary.Time_Slice.Last <= Buffer'Last);
      end if;

      Success := True;
   end PUS_Deserialize;
end Pusparser.Core.Telemetry;
