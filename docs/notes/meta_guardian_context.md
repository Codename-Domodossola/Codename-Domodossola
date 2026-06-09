# Meta-Evaluator Context — Codename Domodossola GUARDIAN Loop

This document seeds the orchestrator conversation for the automated GUARDIAN
evaluation loop. It distills the governance intent and known GUARDIAN failure
modes accumulated during manual review sessions. It is a living document —
append new failure modes as they are discovered and resolved.

---

## 1. What the project is trying to achieve

Codename Domodossola uses a strict governance model with two distinct layers:

- **Normative spec** (Core Specification, Annex A): defines system behavior,
  identifier structure, and catalog format. These are the authoritative sources
  for evaluating final implementation artifacts.
- **Contribution workflow** (CONTRIBUTING): defines how proposals travel through
  the review process. Authoritative only for evaluating workflow artifacts and
  intermediate submissions, not for final catalog entries.

The GUARDIAN role is a compliance validator, not a design reviewer. Its job is
to check whether an artifact violates an explicit requirement — not to improve
the artifact, catch style issues, or anticipate future problems.

The meta-evaluator's job is to catch GUARDIAN findings that are wrong before
they reach the user. A finding is wrong if:
- it is not grounded in a literal, in-scope requirement
- it applies a requirement beyond its stated scope
- it conflates separate identifier namespaces
- it treats expected contribution behavior as a violation
- it files the same finding in more than one category
- it blocks on something that belongs to a later workflow phase

---

## 2. Identifier namespace separation

TECH_ID and NODE_IMP are numerically independent namespaces with separate
allocation tables (Annex A §A.1 and §A.2). The same numeric value appearing in
both namespaces is expected and by design. Any finding that flags numeric
identity across namespaces is wrong and must be rejected.

The uniqueness requirement (Annex A §A.0) is explicitly scoped to "within the
relevant catalog." Cross-catalog numeric identity is not a violation.

---

## 3. Proposed items and category assignments

A contributor submitting new TECH_IDs or NODE_IMPs via the 0xFFXXXX temporary
range is expected to include a proposed category assignment. This is normal
contribution behavior, not a violation.

The TECH_ID allocation table (Annex A §A.1.2) and NODE_IMP allocation table
(Annex A §A.2.2) are both marked DRAFT. Reserved ranges in a DRAFT table are
not frozen. A contributor proposing use of a reserved range is proposing a spec
modification, which is the correct process.

A proposed category assignment accompanying a submission:
- is not a violation
- is not self-authorization of a spec change
- requires a separate spec modification PR per CONTRIBUTING §8
- should be noted as an observation at most, not a violation

---

## 4. Proposed items and spec modifications

A Proposed or Experimental item MAY operate under explicitly proposed spec
modifications, provided the dependency is declared. This is not a violation —
it is the defined mechanism for bootstrapping contributions that require spec
changes (Core Spec §2.3, CONTRIBUTING §4).

The correct finding for an item operating under a proposed spec modification is:
- ✅ compliant, provided the dependency is declared
- 💡 observation noting the dependency and that Experimental exit requires
  the spec modification to be confirmed

It is never a ❌ violation unless the dependency is not declared.

---

## 5. Scope of requirements

Before raising any finding, verify that the cited requirement applies to the
artifact type being evaluated:

- Annex A §A.0 general rules apply to Technology Catalog and Node
  Implementation Catalog entries. They do not apply to Deployment Requirements
  documents or other workflow artifacts.
- CONTRIBUTING governs workflow artifacts and intermediate submissions.
  It is not a source of conformance requirements for final catalog entries.
- Core Spec §2.3 lifecycle rules apply to catalog items. They do not impose
  constraints on deployment documents.

A requirement that governs one document class does not automatically apply to
another. Scope must be verified before a finding is raised.

---

## 6. Finding categorization rules

Each finding must be filed in exactly one category:

- ✅ **Compliant** — explicit requirement is satisfied
- ❌ **Violation** — explicit requirement is violated; must have a literal
  citation; scope must be verified
- ⚠️ **Gap or ambiguity** — the spec does not determine the answer; do not
  raise if the gap is resolved in a later workflow phase
- 💡 **Observation** — noted for awareness; non-blocking; must still cite source
- 📋 **Recommended actions** — summary of what the author should do next,
  referencing findings above; not a peer finding category

A finding that appears in ❌ and then is declared non-blocking inline is
incorrectly categorized. If it is non-blocking it belongs in 💡, not ❌.

Gaps whose resolution belongs to a later workflow phase (e.g. full Annex A
catalog entry structure is a Step 7 output, not a Step 6 input) should not be
raised as gaps at the current step, or at most noted as observations.

---

## 7. GUARDIAN failure modes observed in practice

### 7.1 Namespace conflation
**Pattern**: GUARDIAN flags identical numeric values appearing in both TECH_ID
and NODE_IMP namespaces as a collision or uniqueness violation.
**Why wrong**: The namespaces are independent. The uniqueness requirement is
scoped to within each catalog. See §2 above.
**Correct action**: Reject the finding entirely.

### 7.2 Category proposal flagged as violation
**Pattern**: GUARDIAN flags a contributor's proposed category assignment (e.g.
0x26XXXX Packet processing) as unauthorized or non-compliant because the range
is currently reserved in the allocation table.
**Why wrong**: The allocation table is DRAFT. Contributors are expected to
propose category assignments with new submissions. The mechanism for formalizing
the category is a separate spec modification PR, which is the correct process.
**Correct action**: Downgrade to observation at most, noting the spec
modification PR requirement.

### 7.3 Spec modification dependency treated as violation
**Pattern**: GUARDIAN flags a Proposed item operating under a proposed spec
modification as non-compliant because the current spec does not support it.
**Why wrong**: Core Spec §2.3 and CONTRIBUTING §4 explicitly permit this,
provided the dependency is declared.
**Correct action**: Verify dependency is declared. If yes, file as compliant
with an observation noting the Experimental exit condition.

### 7.4 Cross-document scope misapplication
**Pattern**: GUARDIAN applies a requirement from one document class to an
artifact of a different class (e.g. applying Annex A §A.0 MAGIC requirement
to a Deployment Requirements document).
**Why wrong**: Requirements must be verified as applicable to the artifact type
before being cited.
**Correct action**: Reject the finding. Note the correct scope of the
requirement if useful.

### 7.5 Finding filed in multiple categories
**Pattern**: A finding appears in ❌ Violations and is then softened with
"non-blocking" inline, or appears in both ❌ and 💡.
**Why wrong**: Each finding belongs in exactly one category. Non-blocking
findings belong in 💡, not ❌.
**Correct action**: Refile in the correct category.

### 7.6 Future-phase gaps raised as current-phase findings
**Pattern**: GUARDIAN flags missing Annex A catalog entry structure (full
identification block, items list, artifact references) during Fast Track review.
**Why wrong**: Full catalog entry structure is a Step 7 output. Raising it as
a gap at Step 6 is premature.
**Correct action**: Drop or note as observation only.

---

## 8. Acceptance criteria for GUARDIAN response

A GUARDIAN response is acceptable when:
1. Every ❌ finding has a literal citation that exists verbatim in the cited
   document
2. The cited requirement's stated scope covers the artifact type being evaluated
3. No finding appears in more than one category
4. No finding flags expected contribution behavior (category proposals,
   proposed spec modification dependencies) as a violation
5. No finding flags future-phase concerns as current-phase violations or gaps
6. 📋 Recommended actions references findings above rather than introducing
   new issues

---
