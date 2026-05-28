# Codename Domodossola Deployment Configuration
# TP
## status: architectural requirement consolidation
## updated: 2026-05-04 08:07

---

# 0. Deployment Context

## 0.1 Deployment Goal

The TP deployment is intended to validate a minimal but operational Codename Domodossola system under realistic home deployment conditions.

The goal is not merely to prototype hardware, but to validate:
- architectural layering
- semantic model
- authority model
- transport abstraction
- persistence separation
- deployment workflow

under realistic home deployment conditions.

The system is intended to evolve incrementally while remaining compliant with the Core Specification.

---

## 0.2 Immediate goals

Implement the smallest fully compliant Codename Domodossola deployment that is:
- operational
- useful in daily life
- architecturally representative
- auditable
- extensible

The immediate deployment target is a solar water heater monitoring system, including:

- one single sensor telemetry node
- one aggregation/storage node
- wired UART transport
- local-only operation
- verbose logging

---

## 0.3 Medium-Term Expansion Goals

Planned medium-term expansion includes:

- multiple sensors on telemetry node
- water flow sensing
- RTC integration
- ambient sensing in multiple rooms
- external environmental sensing
- compost temperature profiling
- local dashboard/display nodes
- semantic persistence
- historical visualization
- configurable aggregation behavior
- kitchen display node showing:
  - tank temperature
  - possible simulated pipe heat wave visualization
  
---

## 0.4 Long-Term Exploratory Goals

Potential future expansions include:

- surveillance or wildlife cameras
- automatic gate integration
- weather station infrastructure
- smart lighting and presence control
- broader automation infrastructure
- heterogeneous radio transports
- relay infrastructure
- transport bridging
- distributed dashboards
- richer semantic processing

These directions are exploratory only and are not architecturally committed.

---

## 0.5 Available Hardware

Current available hardware:

- 3 Arduino Nano (ELEGOO)
- 3 ESP32-WROOM-32D development boards
- 1 ESP32-C3 with 0.42" display
- 1 I2C LCD display
- 2 SX1278 LoRa modules
- 25 DS18B20 sensors
- 3 water flow sensors
- 3 RTC modules
- SD card adapter
- CR2032 holders
- breadboard power modules
- generic electronics kit
- 5V relays

---

# 1. Node Requirement Entry — Attic Telemetry Node

## 1.1 Intended Role

The node is intended to:

- acquire temperature measurements
- locally evaluate transmission conditions
- generate authenticated packets
- transmit telemetry to aggregation nodes

The node is not intended to:

- provide administrative services
- manage semantic interpretation
- manage remote peers dynamically
- provide runtime configuration interfaces

---

## 1.2 Hardware Direction

Current hardware target:

- Arduino Nano (ATmega328P)
- one DS18B20 temperature sensor

Possible future evolution:

- multiple DS18B20 sensors
- water flow sensors
- RTC integration

---

## 1.3 Operational Constraints

The node shall:

- operate with bounded RAM usage
- operate with bounded flash usage
- maintain deterministic runtime behavior
- tolerate receiver absence
- tolerate packet loss
- remain operational without network connectivity

---

## 1.4 Communication Requirements

Current transport requirement:

- UART transmission

Current physical model:

- Nano TX connected to ESP32 RX through voltage divider
- shared ground required

The node shall:

- support authenticated packet transmission
- support replay protection metadata
- support deterministic packet generation

The node is not required to:

- receive runtime commands
- negotiate transports
- negotiate cryptographic suites

---

## 1.5 Security Requirements

The node shall:

- authenticate all transmitted packets
- use static cryptographic material
- support replay protection

Current cryptographic direction:

- keyed BLAKE2s authentication

Possible future alternative:

- SipHash authentication

Current confidentiality policy:

- public telemetry only

Payload encryption is therefore not currently required.

---

## 1.6 Semantic Requirements

The node shall:

- generate semantic telemetry constructs
- support deterministic semantic encoding
- support transmission rule evaluation

The node shall not:

- dynamically invent arbitrary semantic structures
- depend on external semantic negotiation

The node may support:

- deterministic runtime-derived semantic structures derived from immutable hardware identifiers

Possible future requirement:

- deterministic handling of multiple DS18B20 sensor identities

---

## 1.7 Persistence Requirements

No persistent storage is currently required.

Possible future requirements:

- persistent hardware identity bindings
- persistent replay state

---

## 1.8 Administrative Requirements

Current administrative direction:

- static configuration
- no mutable runtime administration
- no runtime peer enrollment

Possible future evolution:

- authenticated mutable sensor binding configuration

---

## 1.9 Open Design Points

Unresolved future design topics:

- multi-sensor semantic encoding model
- persistent sensor identity handling
- future low-power transport migration

---

# 2. Node Requirement Entry — Aggregation and Storage Node

## 2.1 Intended Role

The node is intended to:

- receive packets
- validate packets
- validate replay state
- interpret constructs
- resolve remote semantic information
- maintain verbose operational logging
- expose a local Web UI

The node acts as the current semantic interpretation authority for the deployment.

---

## 2.2 Hardware Direction

Current hardware target:

- ESP32-WROOM-32D
- SD card storage
- WiFi connectivity

Possible future evolution:

- additional transports
- relay functionality
- multi-service aggregation behavior

---

## 2.3 Operational Constraints

The node shall:

- operate without Internet dependency
- tolerate malformed packets
- tolerate unsupported constructs
- maintain deterministic packet processing behavior
- maintain bounded replay state

---

## 2.4 Communication Requirements

Current transport requirement:

- UART packet reception

Possible future transports:

- LoRa
- WiFi
- low-power radio transports

The node shall:

- authenticate packets before interpretation
- reject invalid replay state
- tolerate unsupported semantic constructs without unsafe behavior

---

## 2.5 Security Requirements

The node shall:

- maintain peer authentication state
- maintain replay validation state
- support deterministic authentication processing

Current cryptographic direction:

- keyed BLAKE2s authentication

Possible future alternative:

- SipHash authentication for constrained peer compatibility

Current confidentiality policy:

- public telemetry only

Payload decryption is therefore not currently required.

---

## 2.6 Semantic Requirements

The node shall:

- decode semantic constructs
- associate remote semantic information with deployment-local meaning
- tolerate semantic evolution without invalidating operational logs

The node may support:

- deterministic hardware-derived semantic structures
- multiple semantic encoding models
- receiver-side semantic remapping

Semantic persistence is considered a medium-term feature and is not currently required for the initial deployment slice.

---

## 2.7 Logging Requirements

The node shall maintain verbose operational logging.

The logging system is intended to support:

- auditability
- debugging
- replay analysis
- protocol validation
- deployment diagnostics

Logging may include:

- received packets
- packet validation failures
- replay failures
- semantic interpretation failures
- transport events
- administrative events
- internal node errors

The logging layer shall remain independent from future semantic persistence mechanisms.

---

## 2.8 Administrative Requirements

The node shall support:

- authenticated administration
- peer configuration
- semantic configuration
- persistent configuration storage

The node may support:

- AP fallback mode
- local-only management interfaces

---

## 2.9 UI Requirements

The node shall expose a local Web UI.

Current expected functions:

- live telemetry display
- node status visibility
- log inspection

Possible future functions:

- historical visualization
- semantic remapping
- deployment diagnostics
- thermal-flow visualization

---

## 2.10 Open Design Points

Unresolved future design topics:

- logging storage structure
- semantic persistence format
- future relay behavior
- future transport bridging
- long-term semantic history management

---

# 3. Future Candidate Node — Ultra-Low-Power Ambient Sensor

## 3.1 Intended Role

Future battery-powered ambient telemetry node.

---

## 3.2 Candidate Hardware

Current exploratory direction:

- ATtiny MCU
- CR2032 coin cell
- OOK or FSK transmitter
- humidity/temperature sensor

---

## 3.3 Expected Operational Model

The node is expected to:

- operate primarily in deep sleep
- aggregate measurements locally
- transmit compact authenticated telemetry periodically
- minimize radio airtime
- tolerate receiver absence

---

## 3.4 Expected Semantic Model

Current semantic direction:

- compact ordered telemetry encoding
- deterministic semantic encoding
- bounded payload size

---

## 3.5 Expected Security Direction

Current direction:

- compact authenticated packets
- replay protection
- no payload encryption

---

# 4. Future Candidate Node — Compost Temperature Profiling Node

## 4.1 Intended Role

Future multi-sensor temperature profiling node.

---

## 4.2 Candidate Hardware Direction

Current exploratory direction:

- multiple DS18B20 sensors
- fixed spatial probe layout

---

## 4.3 Expected Requirements

The node is expected to support:

- deterministic sensor identity continuity
- stable sensor ordering
- multi-sensor semantic encoding
- bounded runtime behavior

Possible future commissioning direction:

- human-assisted sensor ordering procedure

---

# 5. Future Candidate Node — Kitchen Display Node

## 5.1 Intended Role

Future local visualization node.

---

## 5.2 Candidate Hardware Direction

Current exploratory direction:

- ESP32-C3
- integrated display

---

## 5.3 Expected Functions

The node may support:

- tank temperature display
- ambient telemetry display
- semantic visualization
- future thermal-flow visualization
- 