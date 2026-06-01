# Codename Domodossola Core Specification 
## Version 1.0 — alpha 1
## updated: 2026-05-17 20:08

# 0. Document Conventions
## 0.1 Normative Language
The key words MUST, MUST NOT, REQUIRED, SHOULD, SHOULD NOT, RECOMMENDED, NOT RECOMMENDED, MAY and OPTIONAL are to be interpreted as described in RFC 2119.

## 0.2 Document Hierarchy
The document **Codename Domodossola Ethos** defines the philosophical and ethical foundations of Codename Domodossola. It is non-normative and defines no protocol behavior, architectural invariants, or implementation requirements. These are defined exclusively in the system specification documents.

The Codename Domodossola System Specification consists of the following documents, with strict separation of concerns:
1. **Codename Domodossola Core Specification** (this document) <br>Defines the system model and the invariants applying across all implementations and deployments. It defines the abstract reference framework without defining technologies or deployment instances.
2. **Codename Domodossola Core Specification Annex A: Subordinate Documents Specification** <br>Defines the normative structure and minimum required content of subordinate documents.
3. **Codename Domodossola Technology Catalog** <br>Defines the technologies used in the system, identified by unique `TECH_ID`s, for selection in node design.
4. **Codename Domodossola Node Implementation Catalog** <br>Defines concrete node designs, identified by unique `NODE_IMP`s, that specify coherent compositions of technologies and their realized capabilities, excluding deployment-specific concerns.
5. **Codename Domodossola Deployment Configuration** <br>Defines a specific system instance. It records node instances identified by `UID` and the configuration choices governing a single deployment. It does not define system-wide rules.

All lower-level documents MUST remain consistent with the Core Specification and MUST NOT alter or redefine its invariants.

# 1 Design Goals
Codename Domodossola is a distributed monitoring and automation architecture, assuming:
- no cloud or Internet dependency;
- heterogeneous nodes and technologies;
- unreliable or constrained transport;
- explicit authority boundaries;
- deterministic and auditable behavior;
- incremental deployment and extension;
- DIY-friendly, low-cost deployments;
- KISS principle.

## 1.1 Non-Goals
Codename Domodossola does not aim to reinvent the existing open-source home automation stack. Its purpose is to provide a more deterministic architectural framework with explicit authority boundaries and lower hardware requirements, accepting less automatic integration in exchange for tighter control and simpler deployment.

The system does not guarantee interoperability across arbitrary nodes or deployments.
Interoperability and correctness are properties of a coherent deployment, not of protocol compliance alone. They depend on consistent configuration of `TECH_ID`s, semantic models, and node state.
The architecture does not enforce compatibility, negotiation, or automatic cross-node validation. As a result:
- nodes MAY be protocol-compliant yet unable to interpret each other’s data;
- deployments MAY be formally valid but non-functional.
Lack of interoperability MUST NOT result in undefined or unsafe behavior.
This trade-off favors flexibility, explicit control, and simplicity over self-healing behavior.

# 2 System Model
## 2.1 Overview
The system is composed of **Nodes** identified by `UID`s.
Node implementations are defined exclusively through Node Implementation Catalog entries and identified by `NODE_IMP`s.
All hardware and software technologies used in the system are defined exclusively through Technology Catalog entries and identified by `TECH_ID`s.
A node exposes a finite set of supported `TECH_ID`s derived entirely from its `NODE_IMP`. No runtime capability discovery or negotiation exists beyond this static definition.
Nodes interact exchanging **Packets**, that carry opaque **Payloads**, which encode **Constructs** and represent **Semantic Values**.

## 2.2 System Identity and Namespace
The constant `MAGIC = 0xC3D94F` defines the identity of the Codename Domodossola protocol and its associated identifier namespace.
Systems using a different `MAGIC` value are not Codename Domodossola and MUST be treated as foreign.
Within this namespace:
- the meaning and structure of `TECH_ID` and `NODE_IMP` are fixed;
- all compliant nodes share the same identifier semantics.
Allocated identifier ranges are frozen. Unallocated ranges MAY be assigned in future revisions, provided they are strictly additive and do not alter existing identifiers.
Any change affecting:
- the structure or interpretation of `TECH_ID` or `NODE_IMP`;
- the semantics of existing identifier ranges;
- the rules governing catalog interpretation;
MUST result in a different `MAGIC` value and therefore defines a different protocol.

## 2.3 Lifecycle
All `TECH_ID`s and `NODE_IMP`s MUST be assigned exactly one lifecycle state:
- **Proposed** — development-stage definitions not yet admitted to the official catalog; MUST use temporary identifiers as defined in Annex A; MAY change or be removed without stability guarantees; MUST NOT be relied upon for interoperability between deployments;
- **Experimental** — officially admitted to the catalog and intended for broader review and testing; MUST be assigned immutable identifiers; MAY change or be removed without stability guarantees;
- **Active** — approved for deployment and intended for general use;
- **Legacy** — SHOULD NOT be newly deployed; existing use MAY continue and SHOULD be supported by Active implementations;
- **Retired** — MUST NOT be newly deployed; existing instances SHOULD be decommissioned or updated.

Lifecycle state is a catalog-level concept and MUST NOT influence runtime behavior or be inferred or modified by system operation.
Each `TECH_ID` and each `NODE_IMP` becomes immutable once it exits the `Experimental` lifecycle state. After this point:
- it MUST NOT be modified;
- it MUST NOT be removed;
- new `TECH_ID`s and `NODE_IMP`s MAY be added.

# 3 Core Entities and Identifiers
## 3.1 Node
A node is a physical hardware entity that:
- MUST have exactly one `UID`;
- MUST implement at least one `authentication TECH_ID`;
- MUST conform to exactly one `NODE_IMP`.
Identity MUST NOT imply authority.

## 3.2 Packet
A packet is the transmission unit.
A packet contains:
- MAGIC (3 bytes)
- FLAGS (1 byte)
- TOTAL_LENGTH (2 bytes)
- ORIGIN_UID (8 bytes, present if FLAGS bit 0 is set)
- DEST_UID (8 bytes, present if FLAGS bit 1 is set)
- CRYPTO_AUX (suite-defined, nonce or other auxiliary crypto metadata)
- PAYLOAD (encrypted if FLAGS bit 2 is set)
- AUTH_TAG (suite-defined)

Constraints:
- At least one of ORIGIN_UID or DEST_UID MUST exist.
- The packet layer MUST treat PAYLOAD as opaque.

## 3.3 Payload
The PAYLOAD is a transmitted byte sequence.
A PAYLOAD is:
- either a cleartext Construct; or
- an encrypted Construct, as indicated by packet `FLAGS` bit 2.
The packet layer treats PAYLOAD as opaque.

## 3.4 Construct
A Construct is defined as:
`Construct := TECH_ID (3 bytes) | data`
A Construct:
- MUST begin with a `construct TECH_ID`;
- is always cleartext;
- is self-describing via its `construct TECH_ID`;
- is opaque unless the `construct TECH_ID` is supported;
- MAY contain nested Constructs.
A `construct TECH_ID` is either a `semantic TECH_ID` or a `transformation TECH_ID`.
A `semantic TECH_ID` encodes `SEMANTIC_NAME` and `SEMANTIC_VALUE`. The `UID` component of the Semantic Value MUST NOT be encoded in the Construct.

## 3.5 Semantic Value
A Semantic Value is a logical tuple:
<UID, SEMANTIC_NAME, SEMANTIC_VALUE>
Semantic Values represent all L2 data exchange.
- `UID` is bound to the authenticated packet identity (§5.1);
- Name and Value are encoded into Constructs using `semantic TECH_ID`s.
Semantic Values are the canonical runtime data model and exist independently of representation.

## 3.6 MAGIC
The constant `MAGIC`, as defined in §2.2, identifies Codename Domodossola packets.
Packets not beginning with MAGIC MUST be considered foreign artifacts and handled exclusively by a `translation TECH_ID`.

## 3.7 UID
A UID is a 64-bit random identifier assigned to nodes at manufacturing.
It:
- MUST be globally unique;
- MUST be immutable;
- MUST NOT imply trust or authority.

## 3.8 TECH_ID
A TECH_ID is the 24-bit identifier of any composable technology described in the Technology Catalog and used in nodes, including:
- hardware
- software
- transport
- cryptography
- semantic encoding
- transformation logic
A `TECH_ID`:
- MUST fully define behavior;
- MAY reference other TECH_IDs or external technologies;
- MUST be treated as atomic;
- MUST change when definition changes, except if lifecycle state is Experimental.
When referencing an external technology, the TECH_ID defines the mapping to the Codename Domodossola attribute model (§4.2).
Each `TECH_ID` MUST be assigned a lifecycle state, as defined in §2.3.

## 3.9 NODE_IMP
A NODE_IMP is the 24-bit identifier of a node implementation described in the Node Implementation Catalog.
It defines:
- composition of `TECH_ID`s;
- cryptographic suites;
- attribute bindings, as defined in §4.2;
- registry structure;
- firmware and build;
- hardware specification;
- packaging.
A `NODE_IMP`:
- MUST fully define the behavior of the node;
- MUST be treated as atomic;
- MUST change when definition changes, except if lifecycle state is Experimental.
Each `NODE_IMP` MUST be assigned a lifecycle state, as defined in §2.3.

# 4 Node Architecture Model
## 4.1 Trust Levels
The system defines a single ordered classification axis called **Trust Level**, used uniformly to constrain mutability, visibility, and authority over all node state.

Trust Levels:
- **L0 — Hardcoded**: immutable at runtime; defined at manufacturing or compilation time
- **L1 — Administrative**: mutable only via authenticated administrative mechanisms
- **L2 — Runtime**: fully runtime-managed state, subject to execution behavior

Properties:
- Trust Levels form a total order of authority, where L0 > L1 > L2 in terms of immutability constraints
- Every attribute, variable, and registry field MUST be assigned exactly one Trust Level
- Trust Level assignment is static per definition site and MUST NOT change at runtime
- Higher-trust levels MAY constrain lower-trust levels, but NOT vice versa

## 4.2 Attribute Model
Attributes are named `TECH_ID` parameters representing their configurable interface.
A `TECH_ID` defines the set of exposed attributes.
`TECH_ID`s MAY restrict attribute trust levels.

### Attribute Inheritance
`TECH_ID`s MUST explicitly handle all attributes exposed by upstream technologies, as either:
- constant binding (fixed value);
- domain constraint (restricted subset of an upstream domain); or
- domain exposure (propagated domain).
- inheritance MUST NOT downgrade trust level;

### Trust Level Assignment
Each attribute MUST be assigned exactly one Trust Level (L0, L1, L2) as defined in §4.1.
- Trust Levels are assigned by `NODE_IMP`;
- `NODE_IMP` MAY restrict Trust Levels constraints defined by `TECH_ID`s;
- `NODE_IMP` MUST NOT relax Trust Level constraints defined by `TECH_ID`s.
Attributes affecting authentication, authorization, or interpretation of L2 data MUST NOT be assigned L2 — Runtime Trust Level.

## 4.3 TECH_ID Composition
A node is defined as a composition of `TECH_ID`s constrained by its `NODE_IMP`.
- The set of available technologies in a node is fully determined by its `NODE_IMP`;
- All attribute bindings are finalized at the `NODE_IMP` level;
- No runtime extension or alteration supported `TECH_ID`s is allowed.

## 4.4 Transformation Semantics
Transformations operate on Constructs and are defined by `transformation TECH_ID`s.
Each `transformation TECH_ID` MUST define:
- a direct transformation (sender side);
- a reverse transformation (receiver side).

Transformations are reversible by definition.

By default one Construct is transformed into one Construct, but some MAY produce multiple Constructs. In such cases, they MUST define:
- grouping/association mechanism;
- completeness condition;
- reassembly procedure.

Transformation chaining is expressed through nested Constructs. Each transformation MUST treat inner Constructs as opaque.

# 5 Security Model
## 5.1 Authentication
All packets MUST be authenticated before processing.
AUTH_TAG MUST authenticate all preceding packet fields from MAGIC through PAYLOAD.
Cryptographic suites are defined by `TECH_ID`s and selected per communication scope at L1 - Administrative configuration.

### Authentication Identity
For each packet, a single **Authentication UID (AUTH_UID)** MUST be derived as follows:
- if `ORIGIN_UID` is present, then `AUTH_UID = ORIGIN_UID`;
- otherwise, `AUTH_UID = DEST_UID`.
Authentication MUST be performed using the cryptographic material associated with `AUTH_UID` in the L2 Peer Registry.
Nodes that support packets without `ORIGIN_UID` (i.e. `FLAGS` bit 0 unset) MUST be able to authenticate packets using their own `UID` entry in the L2 Peer Registry.

## 5.2 Encryption
Encryption:
- is defined by a `TECH_ID`;
- is not explicitly encoded in the packet;
- is selected via peer registry;
- is indicated by `FLAGS` bit 2.
Encryption applies to the Construct to produce the PAYLOAD.

## 5.3 Cryptographic Material
For each communication scope:
- exactly one valid cryptographic suite and key set MUST exist;
- no fallback, negotiation, or concurrent valid keys are allowed;
- old keys MUST be invalidated.

## 5.4 Administrative Plane
The administrative plane governs all L1 — Administrative state.

### Bootstrap material
Each node MUST be associated with bootstrap material containing:
- `UID`;
- `NODE_IMP`.
The bootstrap material MUST be delivered out-of-band.
Bootstrap material MAY include:
- L1 — Administrative cryptographic material;
- L2 — Runtime cryptographic material;
- initial L1 — Administrative state.
Bootstrap material is defined by NODE_IMP and is either:
- Static: remains permanently valid; or
- Rotating: replaced and invalidated after provisioning.

### L1 — Administrative state and mutation
All L1 — Administrative state:
- MUST be explicitly defined;
- controls L2 — Runtime behavior.
- MUST NOT be modified by L2 — Runtime.
Modification of L1 — Administrative state:
- MUST be initiated by a human administrator;
- MUST be authenticated using L1 — Administrative cryptographic material;
- MUST be explicit, atomic, deterministic, and idempotent;
- MUST NOT produce partial states.
Nodes MAY have no mutable L1 — Administrative state, in such cases all configuration is L0 — Hardcoded;

## 5.5 Error Handling
Error handling behaviour MAY be L0 — Hardcoded or configurable at L1 — Administrative level.
Error handling defines the node’s response strategy to runtime errors, including (non-exhaustive):
- silent drop;
- local logging;
- local or remote notification.

## 5.6 Node Security Profile
Security properties emerge from `NODE_IMP` composition and L1 - Administrative configuration.
Hardening is not a standalone property.

# 6 Node State Model
## 6.1 Variables and Semantic Mapping
### Exposed Variables (L0/L1)
An Exposed Variable:
- is defined by `NODE_IMP`;
- represents readable internal state;
- is used as a source for Semantic Values.
`NODE_IMP` MAY define deterministic families of Exposed Variables derived from immutable hardware anchors.

### Assignable Variables (L0/L1)
An Assignable Variable:
- is defined by `NODE_IMP`;
- can be modified via semantic input;
- MUST always have a defined value.
`NODE_IMP` MAY define deterministic families of Assignable Variables derived from immutable hardware anchors.

### Semantic Names (L1 definition, L2 values)
Semantic names are defined by `NODE_IMP` or L1 - Administrative configuration and contain the Values handled at L2 - Runtime.
`NODE_IMP` MAY define deterministic families of Semantic Names derived from immutable hardware anchors.
A Semantic Name deterministically draws it's value from a source, that can be:
- an Exposed Variable;
- a constant value;
- a locally derived value;
- a remote Semantic Value.

### Remote Semantic Data
Semantic Values derived from received packets are attributed to `AUTH_UID` (§5.1).
If `AUTH_UID` differs from the node's own `UID`, the Semantic Value MAY be staged before integration according to L1 — Administrative source mappings.
If `AUTH_UID` equals the node's own `UID`, the Semantic Value MAY be applied directly, subject to L1 — Administrative configuration.
Handling of received data MUST NOT result in unbounded resource consumption.

### Confidentiality
Each Semantic Name has an L1 - Administratively defined confidentiality level:
- Public: may be freely transmitted;
- Confidential: encrypted and restricted to specific peers;
- Private: MUST NOT be transmitted.

## 6.2 Node Registries
### L2 Peer Registry (L1 — Administrative)
Each entry defines a peer relationship, with:
- peer `UID`;
- peer `NODE_IMP`;
- inbound suite + key;
- outbound suite + key;
- optional metadata.

Properties:
- exactly one valid entry per peer;
- MAY store keys directly or reference secure storage;
- MAY be degenerate.

### Semantic Registry
Contains:
- Semantic Name (L1 — Administrative);
- Source definition (L1 — Administrative);
- Confidentiality (L1 — Administrative);
- Semantic Value (L2 — Runtime);
- metadata.

### Assignable Variable Registry
Contains:
- Assignable Variable (L0 — Hardcoded);
- source binding (L1 — Administrative);
- value (L2 — Runtime);
- metadata.

### Rule Registry (L1 — Administrative)
Defines transmission behavior.
Each rule contains:
- trigger condition;
- semantic inputs;
- recipients;
- transformation chain.
Available transformations are defined by `NODE_IMP` and selected by rule configuration.

All registries:
- have fields constrained by trust level;
- MAY be further restricted by `NODE_IMP`, but MUST NOT be relaxed.

# 7 Interaction Model
## 7.1 General
Nodes communicate by transmitting Constructs via packets.
Interpretation is:
- recursive;
- all-or-nothing.
If any step of the Processing Pipeline, as defined in §7.2, results in an error:
- processing MUST stop;
- the Packet/Construct is uninterpretable;
- state mutation MUST NOT occurr;
- error MUST be handled according to `NODE_IMP` or configuration.

## 7.2 Processing Pipeline (Receiver)
Upon reception:
1. Validate packet structure (MAGIC and TOTAL_LENGTH)
2. Parse FLAGS and derive UIDs
3. Lookup peer registry 
4. Verify authentication 
5. Decrypt PAYLOAD if required 
6. Interpret Construct via nested reverse transformations
7. Return semantic values

## 7.3 Transmission Model
Transmission is Push based and defined by node rules.
A rule defines:
- trigger condition;
- semantic inputs;
- recipients;
- transformation chain (via selected `transformation TECH_ID`s).
Pull transmission is a special case of push, where the trigger condition is a pull requests.
The available trigger mechanisms are defined by `NODE_IMP`.

## 7.4 Fragmentation
Fragmentation is defined at two distinct levels:
- **Construct-level fragmentation** is applied when the resulting payload plus overhead exceeds the maximum packet size. It is implemented as a `transformation TECH_ID` and produces multiple Constructs, each transmitted in a separate packet.
- **Transport-level fragmentation** MAY be applied by the `transport TECH_ID` when a complete packet exceeds the transport MTU. It operates on opaque packet data and MUST be reversed before packet authentication.
These mechanisms are independent and MUST NOT be conflated.

## 7.5 Interoperability
Packet validity and interpretability are distinct:
- a valid packet may contain an uninterpretable Construct.
Interpretability depends on shared `TECH_ID` support and is enforced at deployment level.

# 8 Node Interaction Constraints
- Nodes MUST NOT partially interpret Constructs.
- Nodes MUST treat unsupported Constructs as opaque.
- Nodes MUST NOT negotiate TECH_IDs at runtime
- Nodes MUST NOT modify packets in transit.
- Nodes MAY forward packets without authentication.
