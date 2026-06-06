# Codename Domodossola Deployment Configuration
# TP
## status: fast track — pending GUARDIAN review
## updated: 2026-06-06 10:03

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

## 0.2 Immediate Goals

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

# 1. Node Requirement Entry — Telemetry Node

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
- 4-byte nonce carried in CRYPTO_AUX, sourced from monotonic counter

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

---

## 1.7 Persistence Requirements

The node requires non-volatile storage (internal EEPROM) for:

- The four registries (including UID, cryptographic key material, and transmission
  interval): **L0** — written via ISP at manufacturing, immutable at runtime,
  consistent with Core Specification §4.1 ("defined at manufacturing or compilation
  time").
- The monotonic counter epoch: **L2** — written autonomously by firmware at boot
  and at counter wrap, persisted to EEPROM to survive reboots.

No other persistent storage is currently required.

Possible future requirements:

- persistent hardware identity bindings for multiple DS18B20 sensors

---

## 1.8 Administrative Requirements

Current administrative direction:

- static configuration
- no mutable runtime administration
- no runtime peer enrollment
- all four registries present as L0 degenerate instances, stored in EEPROM

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

---

## 2.2 Hardware Direction

Current hardware target:

- ESP32-WROOM-32D
- SD card storage (for persistent logging)
- WiFi connectivity (for Web UI and administrative interface)

Configuration and cryptographic material are stored in ESP32 NVS (flash-backed key-value store). SD card is dedicated to operational logging.

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

Current transport requirements:

- UART packet reception (telemetry ingestion)
- WiFi (local network only, for Web UI and administrative interface)

Possible future transports:

- LoRa
- low-power radio transports

The node shall:

- authenticate packets before interpretation
- reject invalid replay state
- tolerate unsupported semantic constructs without unsafe behavior

---

## 2.5 Security Requirements

The node shall:

- maintain peer authentication state
- maintain replay validation state per peer
- support deterministic authentication processing

Current cryptographic direction:

- keyed BLAKE2s authentication
- 4-byte nonce carried in CRYPTO_AUX, validated against last-seen value per peer

Current confidentiality policy:

- public telemetry only

Payload decryption is therefore not currently required.

---

## 2.6 Semantic Requirements

The node shall:

- decode semantic constructs
- associate remote semantic information with local meaning
- tolerate semantic evolution without invalidating operational logs

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

Log entries are ordered using the node-local monotonic counter. This provides
strict local ordering within and across boot sessions but does not provide
wall-clock time or cross-node correlation.

The logging layer shall remain independent from future semantic persistence mechanisms.

---

## 2.8 Administrative Requirements

The node shall support:

- authenticated administration
- peer configuration
- semantic configuration
- persistent configuration storage

All four registries are present as L1-administrable instances backed by RAM+NVM storage.

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

# 3. Future Candidate Nodes

## 3.1 Ultra-Low-Power Ambient Sensor

Future battery-powered ambient telemetry node. Exploratory direction: ATtiny MCU, CR2032, OOK/FSK transmitter, humidity/temperature sensor. Expected to operate primarily in deep sleep with periodic compact authenticated telemetry.

## 3.2 Compost Temperature Profiling Node

Future multi-sensor temperature profiling node. Exploratory direction: multiple DS18B20 sensors in fixed spatial layout, deterministic sensor identity continuity, multi-sensor semantic encoding.

## 3.3 Kitchen Display Node

Future local visualization node. Exploratory direction: ESP32-C3 with integrated display, tank temperature and ambient telemetry display, future thermal-flow visualization.

---

# 4. Node Composition

## 4.1 Telemetry Node

**NODE_IMP:** `0xFF1001`
**Category:** `0x10XXXX` Fixed sensing nodes
**Human-readable name:** ATmega328P Fixed Sensor

All four registries present as L0 degenerate instances, stored in EEPROM and written via ISP at manufacturing:
- Peer registry: single entry — self (own UID and key material, used to sign outgoing packets per §5.1: AUTH_UID = ORIGIN_UID = own UID)
- Semantic registry: single entry — temperature reading at position 0
- Assignable variable registry: empty
- Rule registry: single rule — read DS18B20, encode, transmit at fixed interval

**Execution model:**
- Setup: load registries from EEPROM, load epoch from EEPROM, initialize monotonic counter, initialize 1-Wire bus, acquire DS18B20 address, initialize UART.
- Loop: WDT-interrupt-driven. MCU sleeps between transmissions; WDT fires at fixed interval, ISR sets flag, main loop wakes, reads DS18B20, encodes construct, gets-and-increments counter, composes and authenticates packet, transmits over UART, returns to sleep.

---

## 4.2 Aggregation and Storage Node

**NODE_IMP:** `0xFF3001`
**Category:** `0x30XXXX`  Local aggregation hubs
**Human-readable name:** ESP32-WROOM-32D aggregator

All four registries present as L1-administrable instances backed by RAM+NVS:
- Peer registry: one entry per known telemetry node (UID, NODE_IMP, key, last-seen CRYPTO_AUX value)
- Semantic registry: semantic name mappings for received telemetry
- Assignable variable registry: currently empty
- Rule registry: currently empty (no outgoing transmissions)

**Execution model:**
- Setup: load peer registry and semantic registry from NVS, load epoch from NVS, initialize monotonic counter, initialize UART, initialize SD, initialize WiFi (local AP or station mode), start Web UI.
- Loop: receive bytes on UART, extract packet (validate MAGIC, TOTAL_LENGTH), parse FLAGS and UIDs, lookup peer in peer registry, verify AUTH_TAG via BLAKE2s, validate CRYPTO_AUX is strictly greater than last-seen value, update last-seen value, decode construct, update semantic registry, write log entry to SD (ordered by local monotonic counter), update Web UI state.

Note: the aggregation node generates no outgoing Codename Domodossola packets in the current deployment slice. The monotonic counter is used exclusively for local log entry ordering.

---

# 5. Technology Composition

## 5.1 Annex A.1.2 TECH_ID Allocation Table Additions

The following addition to the `0x2XXXXX` block is required to accommodate packet processing technologies:

```
0x26XXXX  Packet processing
0x27XXXX–0x2FXXXX  Reserved
```

## 5.2 Proposed TECH_ID Allocation

| Proposed TECH_ID | Human-readable name | Category | Used by |
|---|---|---|---|
| `0xFF1001` | ATmega328P + Arduino core runtime | `0x10XXXX` MCU/SoC + runtime bundles | Telemetry node |
| `0xFF1002` | ESP32-WROOM-32D + Arduino/IDF core runtime | `0x10XXXX` MCU/SoC + runtime bundles | Aggregation node |
| `0xFF1301` | 1-Wire bus | `0x13XXXX` Peripheral interfaces | Telemetry node |
| `0xFF2101` | UART transport | `0x21XXXX` Wired communication | Both nodes |
| `0xFF2501` | Monotonic counter replay validation | `0x25XXXX` Transport integrity | Aggregation node |
| `0xFF2601` | Packet composer | `0x26XXXX` Packet processing | Telemetry node |
| `0xFF2602` | Packet interpreter | `0x26XXXX` Packet processing | Aggregation node |
| `0xFF3001` | DS18B20 temperature sensor | `0x30XXXX` Environmental sensing | Telemetry node; depends on `0xFF1301` |
| `0xFF5001` | SD card storage | `0x50XXXX` Non-volatile storage | Aggregation node |
| `0xFF5101` | Monotonic counter (epoch+RAM, abstract NVM interface) | `0x51XXXX` Runtime persistence | Both nodes |
| `0xFF5301` | Peer registry interface | `0x53XXXX` Registry/state management | Both nodes |
| `0xFF5302` | Semantic registry interface | `0x53XXXX` Registry/state management | Both nodes |
| `0xFF5303` | Assignable variable registry interface | `0x53XXXX` Registry/state management | Both nodes |
| `0xFF5304` | Rule registry interface | `0x53XXXX` Registry/state management | Both nodes |
| `0xFF5311` | EEPROM-backed L0 registry backend | `0x53XXXX` Registry/state management | Telemetry node; candidate for splitting at Step 7 |
| `0xFF5312` | RAM+NVM administrable (L1) registry backend | `0x53XXXX` Registry/state management | Aggregation node; candidate for splitting at Step 7 |
| `0xFF6101` | BLAKE2s keyed authentication | `0x61XXXX` Authentication | Both nodes; requires 4B nonce from NODE_IMP |
| `0xFF7001` | Positional uint8 semantic encoding | `0x70XXXX` Semantic encoding/decoding | Both nodes |
| `0xFFA101` | Web UI | `0xA1XXXX` Dashboards/presentation | Aggregation node |

## 5.3 Semantic Encoding Detail

Proposed TECH_ID `0xFF7001` defines a generic positional uint8 array construct:

- Wire format: `[TECH_ID 3B][value_0 1B][value_1 1B]...[value_n-1 1B]`
- n, scaling parameters, and position-to-variable mappings are defined by NODE_IMP.

Telemetry node mapping:
- n = 1
- Position 0: DS18B20 temperature reading
- Range: [-2°C, 125°C]
- Encoding: `uint8 = (T + 2) * 2`
- Resolution: 0.5°C per LSB

## 5.4 Replay Protection Detail

Proposed TECH_ID `0xFF5101` defines a monotonic counter with the following properties:
- Epoch (2 bytes): persisted to NVM, starts at 0, increments at boot and at counter wrap.
- Counter (2 bytes): RAM-resident, starts at 0 at each boot, increments at every use.
- API: single call that atomically increments and returns the full 4-byte value (epoch || counter).
- The abstract NVM interface is implemented per platform by NODE_IMP (EEPROM on ATmega328P; NVS on ESP32).

Proposed TECH_ID `0xFF2501` validates received CRYPTO_AUX values:
- Maintains last-seen 4-byte counter value per peer in the peer registry.
- Rejects any packet where CRYPTO_AUX is not strictly greater than the last-seen value for that peer.

## 5.5 TECH_ID List per Node

**Telemetry Node — NODE_IMP `0xFF1001` — ATmega328P Fixed Sensor:**

| TECH_ID | Human-readable name |
|---|---|
| `0xFF1001` | ATmega328P + Arduino core runtime |
| `0xFF1301` | 1-Wire bus |
| `0xFF2101` | UART transport |
| `0xFF2601` | Packet composer |
| `0xFF3001` | DS18B20 temperature sensor |
| `0xFF5101` | Monotonic counter |
| `0xFF5301` | Peer registry interface |
| `0xFF5302` | Semantic registry interface |
| `0xFF5303` | Assignable variable registry interface |
| `0xFF5304` | Rule registry interface |
| `0xFF5311` | Hardcoded (L0) registry backend |
| `0xFF6101` | BLAKE2s keyed authentication |
| `0xFF7001` | Positional uint8 semantic encoding |

**Aggregation Node — NODE_IMP `0xFF3001` — ESP32-WROOM-32D aggregator:**

| TECH_ID | Human-readable name |
|---|---|
| `0xFF1002` | ESP32-WROOM-32D + Arduino/IDF core runtime |
| `0xFF2101` | UART transport |
| `0xFF2501` | Monotonic counter replay validation |
| `0xFF2602` | Packet interpreter |
| `0xFF5001` | SD card storage |
| `0xFF5101` | Monotonic counter |
| `0xFF5301` | Peer registry interface |
| `0xFF5302` | Semantic registry interface |
| `0xFF5303` | Assignable variable registry interface |
| `0xFF5304` | Rule registry interface |
| `0xFF5312` | RAM+NVM administrable (L1) registry backend |
| `0xFF6101` | BLAKE2s keyed authentication |
| `0xFF7001` | Positional uint8 semantic encoding |
| `0xFFA101` | Web UI |
