# Packet Utilization Standard Parser

![SPARK Verification](https://img.shields.io/badge/SPARK-proved-brightgreen)

The PUS (Packet Utilization Standard) Parser is a verified library written in Ada SPARK that implements a universal engine for parsing and packing packets in accordance with the **ECSS-E-ST-70-41C (Telemetry and Telecommand Packet Utilization)** and **CCSDS 133.0-B-1 (Space Packet Protocol)** standards.

## Implementation Features

- **Zero-Allocation & Zero-Copy:** The engine operates exclusively using statically allocated memory and raw buffers (`array of Byte`). There is no dynamic memory allocation (`malloc`) or unnecessary data copying.
- **No Dependency on Ada System Packages:** The library is written without using the `System` or `Interfaces` packages.
- **Isolation:** Parsing logic is completely decoupled from the application service layer.

## Verification

The following have been formally proven using GNAT Prove:

- Runtime error
- Integer overflow
- Buffer overflow

## Status

- [x] Telemetry serialization
- [ ] Telemetry deserialization
- [ ] Telecommand serialization
- [ ] Telecommand deserialization
