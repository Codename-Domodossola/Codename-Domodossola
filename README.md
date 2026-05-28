# Codename Domodossola

Codename Domodossola is an open distributed monitoring and automation architecture focused on:
- full user control and operator autonomy
- deterministic and auditable behavior
- explicit authority boundaries
- transport independence
- low hardware requirements
- incremental deployment
- reproducible hardware/software implementations

The project targets heterogeneous deployments ranging from extremely constrained sensor nodes to multi-service aggregation and visualization systems.

Codename Domodossola does not default to reinvention. Existing, well-established solutions are treated as primary candidates and are reused whenever compatible with system constraints and deployment requirements.

The architecture intentionally prioritizes:
- explicit configuration over automatic discovery
- deterministic behavior over implicit integration
- bounded resource usage over feature density
- deployment coherence over universal interoperability

---

## Repository Structure

This repository contains:
- normative documentation
- technology catalogs
- node implementation catalogs
- firmware and software implementations
- hardware designs
- manufacturing definitions
- reproducible build material
- development and validation tooling

### Main directories

- `/docs`
  - specifications
  - catalogs
  - reference documents

- `/software`
  - firmware implementations
  - software tooling
  - tests
  - reproducible build definitions

- `/hardware`
  - schematics
  - PCB layouts
  - BOMs
  - manufacturing files
  - enclosure definitions

- `/*/tools`
  - development utilities
  - validation tools
  - auxiliary tooling

---

## Project Model

The system is built around immutable identifiers:

- `TECH_ID`
  - defines one atomic technology definition

- `NODE_IMP`
  - defines one atomic hardware/software node implementation snapshot

Once a `TECH_ID` or `NODE_IMP` exits Experimental status:
- the definition becomes immutable
- implementation fingerprints become frozen
- material changes require a new identifier

A deployment is defined through:
- node `UID`s
- associated `NODE_IMP`s
- administrative configuration
- peer relationships
- semantic mappings

---

## Licensing

This repository uses multiple licenses depending on directory.

See: `LICENSE` for the complete licensing structure.

---

## Status

The project is currently in early architectural and implementation development.
