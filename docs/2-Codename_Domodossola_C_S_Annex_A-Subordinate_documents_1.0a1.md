# Codename Domodossola Core Specifications Annex A:
# Subordinate Documents Specification
## Version 1.0 — alpha 1
## updated: 2026-06-05 09:52

---

This annex defines the normative structure and minimum required content of subordinate documents referenced by the Codename Domodossola Core Specification (§0.2).

---

# A.0 General Rules

All subordinate documents:

- MUST explicitly reference `MAGIC = 0xC3D94F` (§2.2)
- MUST comply with the Core Specification
- MUST NOT redefine Core Specification invariants

The Technology Catalog and Node Implementation Catalog define and allocate identifiers under the single Codename Domodossola namespace associated with `MAGIC = 0xC3D94F` (§2.2).

A catalog entry MAY define one or more catalog items.

Catalog items contained in the same catalog entry MUST be strictly related. In practice, this means they MUST:
- share the first 16 bits of the identifier
- belong to the same category
- share the same design intent
- represent the same broad functional family
- differ only by version, parameterization, capacity, revision, or similarly bounded variation

Each catalog item MUST have:
- a `TECH_ID` or `NODE_IMP` that is unique within the relevant catalog 
- exactly one lifecycle state (§2.3)

Each catalog item:
- MUST become immutable once it exits the Experimental lifecycle state
- MUST require a new identifier if modified after becoming immutable

A catalog entry MAY include common sections shared by multiple catalog items, but each contained item MUST be clearly identified and normatively distinguishable from the others.

Proposed catalog items are development-stage definitions not yet admitted to the official catalog. Temporary identifiers for Proposed items MUST use the `0xFFXXXX` range, where `XXXX` corresponds to the proposed official identifier’s first four nibbles.

An identifier is only meaningful together with its namespace. `TECH_ID` and `NODE_IMP` are parallel namespaces; equal numeric values in different namespaces are unrelated and never constitute a collision.

In all human-facing text (specs, catalog entries, code comments, commit messages) every `TECH_ID` and `NODE_IMP` value MUST be class-qualified with a sigil: `T:` for `TECH_ID`, `N:` for `NODE_IMP`. The MAGIC constant MUST appear in its canonical form `MAGIC = 0xC3D94F`. Bare `0x…` values are not permitted in such contexts.

In source code, every `TECH_ID` and `NODE_IMP` value MUST be expressed through a constant or variable whose name strictly ends with `TECH_ID` or `NODE_IMP` respectively; bare `0x...` literals for catalog identifiers are permitted only in the definition of such a constant or variable. The MAGIC protocol discriminator MUST be named `MAGIC`.

New catalog items MAY be added without changing `MAGIC`, provided existing immutable items remain unchanged.

Defect correction, behavioral modification, or implementation replacement for an immutable `TECH_ID` or `NODE_IMP` MUST be performed through allocation of a new identifier.

Lifecycle state transitions do not modify the technical definition of a catalog item and MAY occur without changing the identifier.

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
T:0x0XXXXX  INVALID / NULL (MUST NOT be used)

T:0x1XXXXX  Execution substrate
T:0x10XXXX  MCU / SoC + runtime bundles
T:0x11XXXX  Bootloaders / initialization
T:0x12XXXX  Execution environments / schedulers
T:0x13XXXX  Peripheral interfaces
T:0x14XXXX  Debug / programming
T:0x15XXXX  FPGA / programmable logic
T:0x16XXXX  Power / energy
T:0x17XXXX  Firmware update / provisioning / lifecycle (OTA)
T:0x18XXXX–T:0x1FXXXX  Reserved

T:0x2XXXXX  Communication / transport
T:0x20XXXX  Packet encoding / decoding
T:0x21XXXX  Radio communication
T:0x22XXXX  Wired communication
T:0x23XXXX  Link / framing
T:0x24XXXX  Routing / relay / mesh
T:0x25XXXX  Gateway / bridge communication
T:0x26XXXX  Transport integrity
T:0x27XXXX–T:0x2FXXXX  Reserved

T:0x3XXXXX  Sensors
T:0x30XXXX  Environmental sensing
T:0x31XXXX  Node motion/positioning sensing
T:0x32XXXX  External motion/positioning sensing
T:0x33XXXX  Optical sensing
T:0x34XXXX  Electrical measurement
T:0x35XXXX  Human input sensing
T:0x36XXXX  Acquisition / conditioning
T:0x37XXXX  Multi-sensor probes
T:0x38XXXX–T:0x3FXXXX  Reserved

T:0x4XXXXX  Actuation / output
T:0x40XXXX  Displays
T:0x41XXXX  Indicators / notifications
T:0x42XXXX  Relay / switching
T:0x43XXXX  Motor / motion control
T:0x44XXXX  Analog output
T:0x45XXXX  Safety interlocks
T:0x46XXXX  Feedback / closed-loop actuation
T:0x47XXXX–T:0x4FXXXX  Reserved

T:0x5XXXXX  Storage, persistence & state
T:0x50XXXX  Node Registries (as per §6,2)
T:0x51XXXX  Non-volatile storage / databases
T:0x52XXXX  Runtime persistence / state management
T:0x53XXXX  Serialization / encoding
T:0x54XXXX  Event indexing / timebases
T:0x55XXXX  Secure storage
T:0x56XXXX–T:0x5FXXXX  Reserved

T:0x6XXXXX  Cryptography
T:0x60XXXX  Cryptographic suites
T:0x61XXXX  Authentication / MAC
T:0x62XXXX  Encryption
T:0x63XXXX  Key derivation (KDF)
T:0x64XXXX  Random / entropy generation
T:0x65XXXX  Hashing
T:0x66XXXX  Secure elements / TPM
T:0x67XXXX–T:0x6FXXXX  Reserved

T:0x7XXXXX  Construct processing
T:0x70XXXX  Semantic encoding / decoding
T:0x71XXXX  Semantic mapping / routing
T:0x72XXXX  Transformations
T:0x73XXXX  Compression
T:0x74XXXX  Fragmentation
T:0x75XXXX  Semantic requests
T:0x76XXXX–T:0x7FXXXX  Reserved

T:0x8XXXXX  Rule & orchestration
T:0x80XXXX  Rule evaluation
T:0x81XXXX  Event dispatch / triggers
T:0x82XXXX  Scheduling / orchestration
T:0x83XXXX  Transmission control
T:0x84XXXX  Calibration / discovery
T:0x85XXXX–T:0x8FXXXX  Reserved

T:0x9XXXXX  Translation & interoperability
T:0x90XXXX  Protocol translation
T:0x91XXXX  Foreign protocol bridges
T:0x92XXXX  Semantic translation
T:0x93XXXX–T:0x9FXXXX  Reserved

T:0xAXXXXX  UI & interaction
T:0xA0XXXX  Human interfaces
T:0xA1XXXX  Dashboards / presentation
T:0xA2XXXX  Alert / notification presentation
T:0xA3XXXX  Interactive configuration
T:0xA4XXXX–T:0xAFXXXX  Reserved

T:0xBXXXXX  Data processing algorithms
T:0xB0XXXX  Statistical processing
T:0xB1XXXX  Windowed aggregation
T:0xB2XXXX  Filtering / smoothing
T:0xB3XXXX  Physical simulation
T:0xB4XXXX  Synthetic sensors
T:0xB5XXXX  Machine learning
T:0xB6XXXX  System emulation
T:0xB7XXXX–T:0xBFXXXX  Reserved

T:0xCXXXXX  Diagnostics & development
T:0xC0XXXX  Logging / diagnostics
T:0xC1XXXX  Debug instrumentation
T:0xC2XXXX  Test harnesses
T:0xC3XXXX  Compliance verification
T:0xC4XXXX–T:0xCFXXXX  Reserved

T:0xDXXXXX–T:0xEXXXXX  Reserved for future categories

T:0xFXXXXX  Reserved (MUST NOT be used in the official catalog)
T:0xFFXXXX  Proposed / temporary (MUST NOT be used in the official catalog)
```

---

## A.1.3 Entry Requirements

Each `TECH_ID` entry is defined by:

- a normative catalog entry contained in the documentation layer;
- zero or more referenced implementation artifacts contained in implementation directories.

The catalog entry is authoritative.
Implementation artifacts MUST NOT redefine normative behavior independently from the catalog entry.

For each catalog item, the normative definition consists of:

- the shared catalog entry definition;
- the item-specific definitions contained in the Items list and Items variation summary;
- all referenced implementation artifacts applicable to that item.

Where item-specific definitions conflict with shared catalog entry definitions, the item-specific definitions take precedence for that catalog item.

Each `TECH_ID` entry MUST explicitly define the byte order of any  multi-byte integer fields it introduces, in any context where byte order is not otherwise determined by an external standard governing that interface.

---

### Normative Catalog Entry (in `/docs`)

The normative catalog entry MUST include:

#### 1. Identification
- `MAGIC`
- first 16 bits of `TECH_ID`
- human-readable name
- catalog summary (≤ 300 characters, non-normative)

#### 2. Items list
Compact table containing, for each item:
- `TECH_ID`
- human-readable name suffix
- catalog summary detail (≤ 50 characters, non-normative)
- lifecycle state (§2.3)

#### 3. Design Definition
- purpose
- design choices
- trade-offs
- limitations

#### 4. System Assumptions
- operational assumptions
- environmental assumptions
- dependency assumptions

#### 5. Composition Definition (§4.3)
- imported `TECH_ID` list
- dependency relationships
- composition constraints

#### 6. Attribute Model (§4.2)
- inherited attributes (if applicable)
- exposed attributes
- value domains

#### 7. Functional Interface
the complete firmware-facing API:

- function signatures
- input constraints
- output guarantees
- error conditions
- determinism requirements

These functions define the only valid interaction surface between firmware and the technology.

#### 8. Artifact References
The catalog entry MUST reference all implementation artifacts required to fully define the technology.

Referenced artifacts MAY include:
- firmware implementations
- hardware specifications
- manufacturing artifacts
- test artifacts
- reproducibility tooling
- upstream external technologies

Artifact references SHOULD include immutable fingerprints or hashes where applicable.

#### 9. Items variation summary
Full list of all item-specific variations.

---

### Software Artifacts (in `/software`)

Firmware and software artifacts MAY include:

- source code
- build definitions
- reproducible build tooling
- validation tooling
- test harnesses
- generated binaries

Firmware definitions MUST include:
- build procedure
- reproducibility constraints

Firmware artifacts MUST be deterministically reproducible unless explicitly justified as depending on externally non-reproducible tooling.

Firmware artifacts SHOULD define:
- source revision bindings
- build environment constraints
- resulting binary hashes

Firmware and tooling artifacts MUST remain semantically consistent with the normative catalog entry.

---

### Hardware / Manufacturing Artifacts (in `/hardware`)

Hardware and manufacturing artifacts MAY include:

- schematics
- PCB layouts
- BOMs
- enclosure definitions
- 2D drawings
- 3D models
- manufacturing packages
- assembly documentation

Hardware definitions MUST include:
- components
- electrical characteristics
- vendor references

Hardware artifacts SHOULD define deterministic manufacturing references or fingerprints, including where applicable:
- BOM hashes
- PCB manufacturing package hashes
- revision mappings

Hardware artifacts MUST remain semantically consistent with the normative catalog entry.

---

### External Technology Wrappers (if applicable, in `/software` or `/hardware`)

External technology wrappers MUST define:
- Codename Domodossola interface definition
- upstream reference documentation
- explicit semantic mapping

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
- last 8 bits: hardware / firmware variation space

This structure has no runtime meaning.

---

## A.2.2 NODE_IMP Allocation Table (First 8 Bits)

``` DRAFT - to be frozen after experimentation
N:0x0XXXXX  INVALID / NULL (MUST NOT be used)

N:0x1XXXXX  Zero-configuration nodes
N:0x10XXXX  Fixed sensing nodes
N:0x11XXXX  Fixed actuation/control nodes
N:0x12XXXX  Fixed display/indicator nodes
N:0x13XXXX  Fixed relay/repeater nodes
N:0x14XXXX  Fixed appliance/interface nodes
N:0x15XXXX–N:0x1FXXXX  Reserved

N:0x2XXXXX  Configurable field nodes
N:0x20XXXX  Multi-sensor field nodes
N:0x21XXXX  Multi-actuator field nodes
N:0x22XXXX  Hybrid sensing/actuation nodes
N:0x23XXXX  Portable/mobile field nodes
N:0x24XXXX  Low-power / remote field nodes
N:0x25XXXX–N:0x2FXXXX  Reserved

N:0x3XXXXX  Hub / Service Nodes
N:0x30XXXX  Local aggregation hubs
N:0x31XXXX  Dashboard / presentation hubs
N:0x32XXXX  Provisioning / maintenance hubs
N:0x33XXXX  Multi-service integrated hubs
N:0x34XXXX  High-capacity infrastructure hubs
N:0x35XXXX–N:0x3FXXXX  Reserved

N:0x4XXXXX  External Integration Nodes
N:0x40XXXX  Protocol bridge nodes
N:0x41XXXX  External API / service gateways
N:0x42XXXX  Industrial / machine integration nodes
N:0x43XXXX  Legacy system integration nodes
N:0x44XXXX  Multi-protocol translation nodes
N:0x45XXXX–N:0x4FXXXX  Reserved

N:0x5XXXXX  Dedicated Interaction Nodes
N:0x50XXXX  Passive display nodes
N:0x51XXXX  Interactive UI nodes
N:0x52XXXX  Rich dashboard / presentation systems
N:0x53XXXX  Human control interface nodes
N:0x54XXXX  Feedback / alerting nodes
N:0x55XXXX–N:0x5FXXXX  Reserved

N:0x6XXXXX  Dedicated Actuation / Control Nodes
N:0x60XXXX  Simple actuator nodes
N:0x61XXXX  Closed-loop control nodes
N:0x62XXXX  Safety-critical actuation nodes
N:0x63XXXX  Coordinated multi-actuator systems
N:0x64XXXX  Industrial control nodes
N:0x65XXXX–N:0x6FXXXX  Reserved

N:0x7XXXXX  Transport / Relay Infrastructure Nodes
N:0x70XXXX  Single-transport relay nodes
N:0x71XXXX  Multi-transport relay nodes
N:0x72XXXX  Mesh / routing coordination nodes
N:0x73XXXX  Transport bridge / gateway nodes
N:0x74XXXX  Long-range transport infrastructure nodes
N:0x75XXXX–N:0x7FXXXX  Reserved

N:0x8XXXXX–N:0xEXXXXX  Reserved for future node classes

N:0xFXXXXX  Reserved (MUST NOT be used in the official catalog)
N:0xFFXXXX  Proposed / temporary (MUST NOT be used in the official catalog)
```

---

## A.2.3 Entry Requirements

Each `NODE_IMP` entry is defined by:

- a normative catalog entry contained in the documentation layer;
- zero or more referenced implementation artifacts contained in implementation directories.

The catalog entry is authoritative.
Implementation artifacts MUST NOT redefine normative behavior independently from the catalog entry.

For each catalog item, the normative definition consists of:

- the shared catalog entry definition;
- the item-specific definitions contained in the Items list and Items variation summary;
- all referenced implementation artifacts applicable to that item.

Where item-specific definitions conflict with shared catalog entry definitions, the item-specific definitions take precedence for that catalog item.

---

### Normative Catalog Entry (in `/docs`)

The normative catalog entry MUST include:

#### 1. Identification
- `MAGIC`
- first 16 bits of `NODE_IMP`
- human-readable name
- catalog summary (≤ 300 characters, non-normative)

#### 2. Items list
Compact table containing, for each item:
- `NODE_IMP`
- human-readable name suffix
- catalog summary detail (≤ 50 characters, non-normative)
- lifecycle state (§2.3)

#### 3. Design Definition
- architectural intent
- design choices
- trade-offs
- constraints

#### 4. System Assumptions
- operational assumptions
- environmental assumptions
- dependency assumptions

#### 5. Technology Composition (§4.3)
- `TECH_ID` list
- dependency relationships
- composition constraints

#### 6. Attribute Bindings
- attribute trust levels
- propagated constraints

#### 7. Execution Model
Firmware SHOULD structure behavior primarily through invocation of `TECH_ID` defined interfaces, and MAY also use:
- conditional logic
- variable state management

#### 8. Artifact References
The catalog entry MUST reference all implementation artifacts required to fully define the node implementation.

Referenced artifacts MAY include:
- firmware implementations
- hardware specifications
- manufacturing artifacts
- test artifacts
- reproducibility tooling

Artifact references SHOULD include immutable fingerprints or hashes where applicable.

#### 9. Items variation summary
Full list of all item-specific variations.

---

### Firmware / Software Artifacts (in `/software`)

Firmware and software artifacts MAY include:

- source code
- build definitions
- reproducible build tooling
- validation tooling
- deployment tooling
- generated binaries

Firmware definitions MUST include:
- source code
- build procedure
- reproducibility constraints

Firmware MUST be deterministically reproducible.

Firmware artifacts SHOULD define:
- source revision bindings
- build environment constraints
- resulting binary hashes

Firmware and tooling artifacts MUST remain semantically consistent with the normative catalog entry.

---

### Hardware / Manufacturing Artifacts (`/hardware`)

Hardware and manufacturing artifacts MAY include:

- schematics
- PCB layouts
- BOMs
- enclosure definitions
- 2D drawings
- 3D models
- manufacturing packages
- assembly documentation
- mechanical integration files

Hardware definitions MUST include:
- MCU / substrate
- peripherals
- power systems
- physical constraints
- revision mapping
- enclosure design 
- environmental constraints
- mechanical integration

Hardware artifacts SHOULD define deterministic manufacturing references or fingerprints, including where applicable:
- BOM hashes
- PCB manufacturing package hashes
- assembly constraints

Hardware artifacts MUST remain semantically consistent with the normative catalog entry.

---

## A.2.4 Catalog Index

The Node Implementation Catalog MUST provide a complete index containing:

- `NODE_IMP`
- human-readable name
- lifecycle state

---

# A.3 Deployment Configuration

A Deployment Configuration defines one concrete system instance, where each entry is a node identified by `UID` (§3.7).

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
