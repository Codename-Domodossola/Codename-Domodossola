# Codename Domodossola Core Specifications Annex A:
# Subordinate Documents Specification
## Version 1.0 — alpha 1
## updated: 2026-05-06 23:21

---

This annex defines the normative structure and minimum required content of subordinate documents referenced by the Codename Domodossola Core Specification (§0.2).

---

# A.0 General Rules

All subordinate documents:

- MUST explicitly reference `MAGIC = 0xC3D94F` (§2.2)
- MUST comply with the Core Specification
- MUST NOT redefine Core Specification invariants

The Technology Catalog and Node Implementation Catalog define and allocate identifiers under the single Codename Domodossola namespace associated with `MAGIC = 0xC3D94F` (§2.2).

All `TECH_ID`s and `NODE_IMP`s:

- MUST belong to exactly one lifecycle state (§2.3)
- MUST become immutable once they exit the Experimental lifecycle state
- MUST require a new identifier if modified after becoming immutable

Proposed entries are development-stage definitions not yet admitted to the official catalog. Temporary identifiers for Proposed entries MUST use the `0xFFXXXX` range, where `XXXX` corresponds to the proposed official identifier’s first four nibbles.

New entries MAY be added without changing `MAGIC`, provided existing immutable entries remain unchanged.

---

# A.1 Technology Catalog

The Technology Catalog defines and allocates all `TECH_ID`s (§3.8).

Each entry:

- MUST explicitly reference `MAGIC = 0xC3D94F` (§2.2)
- MUST define one or more strictly related `TECH_ID`s
- MUST comply with the Core Specification

Each `TECH_ID` represents one atomic technology definition.

Any change affecting:

- behavior
- interfaces
- semantics
- composition
- dependencies
- hardware definition

MUST result in a new `TECH_ID`.

---

## A.1.1 Internal Allocation Structure

The `TECH_ID` is runtime-opaque.

Within the catalog, allocation is internally structured as:

- first 8 bits: functional category
- middle 8 bits: design and composition space
- last 8 bits: implementation / vendor / revision space

This structure has no runtime meaning.

---

## A.1.2 TECH_ID Allocation Table (First 8 Bits)

``` DRAFT - to be frozen after experimentation
0x0XXXXX  INVALID / NULL (MUST NOT be used)

0x1XXXXX  Execution substrate
0x10XXXX  MCU / SoC + runtime bundles
0x11XXXX  Bootloaders / initialization
0x12XXXX  Execution environments / schedulers
0x13XXXX  Peripheral interfaces
0x14XXXX  Debug / programming
0x15XXXX  FPGA / programmable logic
0x16XXXX  Power / energy
0x17XXXX–0x1FXXXX  Reserved

0x2XXXXX  Communication / transport
0x20XXXX  Radio communication
0x21XXXX  Wired communication
0x22XXXX  Link / framing
0x23XXXX  Routing / relay / mesh
0x24XXXX  Gateway / bridge communication
0x25XXXX  Transport integrity
0x26XXXX–0x2FXXXX  Reserved

0x3XXXXX  Sensors
0x30XXXX  Environmental sensing
0x31XXXX  Node motion/positioning sensing
0x32XXXX  External motion/positioning sensing
0x33XXXX  Optical sensing
0x34XXXX  Electrical measurement
0x35XXXX  Human input sensing
0x36XXXX  Acquisition / conditioning
0x37XXXX  Multi-sensor probes
0x38XXXX–0x3FXXXX  Reserved

0x4XXXXX  Actuation / output
0x40XXXX  Displays
0x41XXXX  Indicators / notifications
0x42XXXX  Relay / switching
0x43XXXX  Motor / motion control
0x44XXXX  Analog output
0x45XXXX  Safety interlocks
0x46XXXX  Feedback / closed-loop actuation
0x47XXXX–0x4FXXXX  Reserved

0x5XXXXX  Storage, persistence & state
0x50XXXX  Non-volatile storage / databases
0x51XXXX  Runtime persistence
0x52XXXX  Serialization / encoding
0x53XXXX  Registry / state management
0x54XXXX  Event indexing / timebases
0x55XXXX  Secure storage
0x56XXXX–0x5FXXXX  Reserved

0x6XXXXX  Cryptography
0x60XXXX  Encryption
0x61XXXX  Authentication
0x62XXXX  Cryptographic suites
0x63XXXX  Random / entropy generation
0x64XXXX  Secure elements / TPM
0x65XXXX–0x6FXXXX  Reserved

0x7XXXXX  Construct processing
0x70XXXX  Semantic encoding / decoding
0x71XXXX  Semantic mapping / routing
0x72XXXX  Transformations
0x73XXXX  Compression
0x74XXXX  Fragmentation
0x75XXXX  Semantic requests
0x76XXXX–0x7FXXXX  Reserved

0x8XXXXX  Rule & orchestration
0x80XXXX  Rule evaluation
0x81XXXX  Event dispatch / triggers
0x82XXXX  Scheduling / orchestration
0x83XXXX  Transmission control
0x84XXXX  Calibration / discovery
0x85XXXX–0x8FXXXX  Reserved

0x9XXXXX  Translation & interoperability
0x90XXXX  Protocol translation
0x91XXXX  Foreign protocol bridges
0x92XXXX  Semantic translation
0x93XXXX–0x9FXXXX  Reserved

0xAXXXXX  UI & interaction
0xA0XXXX  Human interfaces
0xA1XXXX  Dashboards / presentation
0xA2XXXX  Alert / notification presentation
0xA3XXXX  Interactive configuration
0xA4XXXX–0xAFXXXX  Reserved

0xBXXXXX  Data processing algorithms
0xB0XXXX  Statistical processing
0xB1XXXX  Windowed aggregation
0xB2XXXX  Filtering / smoothing
0xB3XXXX  Physical simulation
0xB4XXXX  Synthetic sensors
0xB5XXXX  Machine learning
0xB6XXXX  System emulation
0xB7XXXX–0xBFXXXX  Reserved

0xCXXXXX  Diagnostics & development
0xC0XXXX  Logging / diagnostics
0xC1XXXX  Debug instrumentation
0xC2XXXX  Test harnesses
0xC3XXXX  Compliance verification
0xC4XXXX–0xCFXXXX  Reserved

0xDXXXXX–0xEXXXXX  Reserved for future categories

0xFXXXXX  Reserved (MUST NOT be used in the official catalog)
0xFFXXXX  Proposed / temporary (MUST NOT be used in the official catalog)
```

---

## A.1.3 Entry Requirements

Each entry MUST include:

1. Identification
   - `MAGIC`
   
   For each defined `TECH_ID`:
   - `TECH_ID`
   - human-readable name
   - catalog summary (≤ 300 characters, non-normative)
   - lifecycle state (§2.3)

2. Design Rationale
   - purpose
   - design choices
   - trade-offs
   - limitations

3. System Assumptions
   - operational assumptions
   - environmental assumptions
   - dependency assumptions

4. Composition Definition (§4.3)
   - included `TECH_ID`s
   - dependency constraints

5. Attribute Model (§4.2)
   - inherited attributes (if applicable)
   - exposed attributes
   - value domains

6. Functional Interface
   Each `TECH_ID` MUST define the complete firmware-facing API:

   - function signatures
   - input constraints
   - output guarantees
   - error conditions
   - determinism requirements

   These functions define the only valid interaction surface between firmware and the technology.

7. Hardware Specification (if applicable)
   - components
   - electrical characteristics
   - vendor references

8. External Technology Wrappers (if applicable)
   - Codename Domodossola interface definition
   - upstream reference documentation
   - explicit semantic mapping

9. Known Bugs
   - bug descriptions
   - severity classification
   - lifecycle impact

   This is the only permanently mutable section and MAY evolve after the `TECH_ID` becomes immutable.

---

## A.1.4 Catalog Index

The Technology Catalog MUST provide a complete index containing:

- `TECH_ID`
- human-readable name
- lifecycle state (§2.3)

---

# A.2 Node Implementation Catalog

The Node Implementation Catalog defines and allocates all `NODE_IMP`s (§3.9).

Each entry:

- MUST explicitly reference `MAGIC = 0xC3D94F` (§2.2)
- MUST define one or more strictly related `NODE_IMP`s
- MUST comply with the Core Specification

Each `NODE_IMP` represents one atomic node implementation definition.

Any change affecting:

- technology composition
- firmware
- hardware
- packaging
- build definition
- attribute bindings

MUST result in a new `NODE_IMP`.

---

## A.2.1 Internal Allocation Structure

The `NODE_IMP` is runtime-opaque.

Within the catalog, allocation is internally structured as:

- first 8 bits: node category
- middle 8 bits: architectural design space
- last 8 bits: hardware / firmware revision space

This structure has no runtime meaning.

---

## A.2.2 NODE_IMP Allocation Table (First 8 Bits)

``` DRAFT - to be frozen after experimentation
0x0XXXXX  INVALID / NULL (MUST NOT be used)

0x1XXXXX  Zero-configuration nodes
0x10XXXX  Fixed sensing nodes
0x11XXXX  Fixed actuation/control nodes
0x12XXXX  Fixed display/indicator nodes
0x13XXXX  Fixed relay/repeater nodes
0x14XXXX  Fixed appliance/interface nodes
0x15XXXX–0x1FXXXX  Reserved

0x2XXXXX  Configurable field nodes
0x20XXXX  Multi-sensor field nodes
0x21XXXX  Multi-actuator field nodes
0x22XXXX  Hybrid sensing/actuation nodes
0x23XXXX  Portable/mobile field nodes
0x24XXXX  Low-power / remote field nodes
0x25XXXX–0x2FXXXX  Reserved

0x3XXXXX  Hub / Service Nodes
0x30XXXX  Local aggregation hubs
0x31XXXX  Dashboard / presentation hubs
0x32XXXX  Provisioning / maintenance hubs
0x33XXXX  Multi-service integrated hubs
0x34XXXX  High-capacity infrastructure hubs
0x35XXXX–0x3FXXXX  Reserved

0x4XXXXX  External Integration Nodes
0x40XXXX  Protocol bridge nodes
0x41XXXX  External API / service gateways
0x42XXXX  Industrial / machine integration nodes
0x43XXXX  Legacy system integration nodes
0x44XXXX  Multi-protocol translation nodes
0x45XXXX–0x4FXXXX  Reserved

0x5XXXXX  Dedicated Interaction Nodes
0x50XXXX  Passive display nodes
0x51XXXX  Interactive UI nodes
0x52XXXX  Rich dashboard / presentation systems
0x53XXXX  Human control interface nodes
0x54XXXX  Feedback / alerting nodes
0x55XXXX–0x5FXXXX  Reserved

0x6XXXXX  Dedicated Actuation / Control Nodes
0x60XXXX  Simple actuator nodes
0x61XXXX  Closed-loop control nodes
0x62XXXX  Safety-critical actuation nodes
0x63XXXX  Coordinated multi-actuator systems
0x64XXXX  Industrial control nodes
0x65XXXX–0x6FXXXX  Reserved

0x7XXXXX  Transport / Relay Infrastructure Nodes
0x70XXXX  Single-transport relay nodes
0x71XXXX  Multi-transport relay nodes
0x72XXXX  Mesh / routing coordination nodes
0x73XXXX  Transport bridge / gateway nodes
0x74XXXX  Long-range transport infrastructure nodes
0x75XXXX–0x7FXXXX  Reserved

0x8XXXXX–0xEXXXXX  Reserved for future node classes

0xFXXXXX  Reserved (MUST NOT be used in the official catalog)
0xFFXXXX  Proposed / temporary (MUST NOT be used in the official catalog)
```

---

## A.2.3 Entry Requirements

Each entry MUST include:

1. Identification
   - `MAGIC`
   
   For each defined `NODE_IMP`:
   - `NODE_IMP`
   - human-readable name
   - catalog summary (≤ 300 characters, non-normative)
   - lifecycle state (§2.3)

2. Design Rationale
   - architectural intent
   - design choices
   - trade-offs
   - constraints

3. Technology Composition (§4.3)
   - `TECH_ID` list
   - dependency relationships
   - composition constraints

4. Firmware Definition
   - source reference
   - build procedure
   - binary hash binding
   - reproducibility constraints

5. Hardware Specification
   - MCU / substrate
   - peripherals
   - power systems
   - physical constraints
   - revision mapping

6. Packaging Specification
   - enclosure
   - environmental constraints
   - mechanical integration

7. Attribute Bindings
   - attribute trust levels
   - propagated constraints

8. Execution Model
   Firmware SHOULD structure behavior primarily through invocation of `TECH_ID` defined interfaces, and MAY also use:
   - conditional logic
   - variable state management

9. Known Bugs
   - bug descriptions
   - severity classification
   - lifecycle impact

   This is the only permanently mutable section and MAY evolve after the `NODE_IMP` becomes immutable.

---

## A.2.4 Catalog Index

The Node Implementation Catalog MUST provide a complete index containing:

- `NODE_IMP`
- human-readable name
- lifecycle state

---

# A.3 Deployment Configuration

A Deployment Configuration defines one concrete system instance, where each entey is a node identified by `UID` (§3.7).

Each deployment entry defines one node and MUST include:

- `UID`
- associated `NODE_IMP`
- complete L1 administrative configuration (§5.4)

The L1 administrative configuration includes:

- cryptographic material
- standalone parameter assignments
- Peer Registry
- Semantic Registry
- Assignable Variable Registry
- Rule Registry

---
