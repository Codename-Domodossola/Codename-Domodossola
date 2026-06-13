# Meta-Evaluator Context — Codename Domodossola GUARDIAN Loop

This document seeds the meta-evaluator with accumulated governance knowledge.
It is a living document — append new failure modes and session notes as they are discovered.

---

## 1. Project governance model

Codename Domodossola uses a strict governance model with two distinct layers:

- **Normative spec** (Core Specification, Annex A): defines system behavior, identifier structure, and catalog format. Authoritative for final implementation artifacts.
- **Contribution workflow** (CONTRIBUTING): defines how proposals travel through the review process. Authoritative only for workflow artifacts and intermediate submissions, not for final catalog entries.

Conflict precedence: Core Specification → Annex A → Catalogs → Deployment Configuration.

---

## 2. Identifier namespace separation

TECH_ID and NODE_IMP are numerically independent namespaces with separate allocation tables (Annex A §A.1 and §A.2). The same numeric value appearing in both namespaces is expected and by design. Any finding that flags numeric identity across namespaces is wrong and must be rejected.

The uniqueness requirement (Annex A §A.0) is explicitly scoped to "within the relevant catalog." Cross-catalog numeric identity is not a violation.

---

## 3. Proposed items and category assignments

A contributor submitting new TECH_IDs or NODE_IMPs via the 0xFFXXXX temporary range is expected to include a proposed category assignment. This is normal contribution behavior, not a violation.

The TECH_ID allocation table (Annex A §A.1.2) and NODE_IMP allocation table (Annex A §A.2.2) are both marked DRAFT. Reserved ranges in a DRAFT table are not frozen. A contributor proposing use of a reserved range is proposing a spec modification, which is the correct process.

A proposed category assignment accompanying a submission:
- is not a violation
- is not self-authorization of a spec change
- requires a separate spec modification PR per CONTRIBUTING §8
- should be noted as an observation at most, never a violation

---

## 4. Proposed items and spec modifications

A Proposed or Experimental item MAY operate under explicitly proposed spec modifications, provided the dependency is declared. This is not a violation — it is the defined mechanism for bootstrapping contributions that require spec changes (Core Spec §2.3, CONTRIBUTING §4).

The correct finding for an item operating under a proposed spec modification is:
- ✅ compliant, provided the dependency is declared
- 💡 observation noting the dependency and that Experimental exit requires the spec modification to be confirmed

It is never a ❌ violation unless the dependency is not declared.

---

## 5. Scope of requirements

Before raising any finding, verify that the cited requirement applies to the artifact type being evaluated:

- Annex A §A.0 general rules apply to Technology Catalog and Node Implementation Catalog entries. They do not apply to Deployment Requirements documents or other workflow artifacts.
- CONTRIBUTING governs workflow artifacts and intermediate submissions. It is not a source of conformance requirements for final catalog entries.
- Core Spec §2.3 lifecycle rules apply to catalog items. They do not impose constraints on deployment documents.

---

## 6. Finding categorization rules

Each finding must be filed in exactly one category:

- ✅ Compliant — explicit requirement is satisfied
- ❌ Violation — explicit requirement is violated; must have a literal citation; scope must be verified
- ⚠️ Gap or ambiguity — the spec does not determine the answer; do not raise if the gap is resolved in a later workflow phase
- 💡 Observation — noted for awareness; non-blocking; must still cite source
- 📋 Recommended actions — summary of what the author should do next; not a peer finding category

A finding that appears in ❌ and then is declared non-blocking inline is incorrectly categorized. If it is non-blocking it belongs in 💡, not ❌.

Gaps whose resolution belongs to a later workflow phase should not be raised as gaps at the current step, or at most noted as observations.

---

## 7. GUARDIAN failure modes observed in practice

### 7.1 Namespace conflation
**Pattern**: GUARDIAN flags identical numeric values appearing in both TECH_ID and NODE_IMP namespaces as a collision or uniqueness violation.
**Why wrong**: The namespaces are independent. The uniqueness requirement is scoped to within each catalog.
**Correct action**: Reject the finding entirely.

### 7.2 Category proposal flagged as violation
**Pattern**: GUARDIAN flags a contributor's proposed category assignment as unauthorized because the range is currently reserved in the allocation table.
**Why wrong**: The allocation table is DRAFT. Contributors are expected to propose category assignments with new submissions.
**Correct action**: Downgrade to observation at most, noting the spec modification PR requirement.

### 7.3 Spec modification dependency treated as violation
**Pattern**: GUARDIAN flags a Proposed item operating under a proposed spec modification as non-compliant because the current spec does not support it.
**Why wrong**: Core Spec §2.3 and CONTRIBUTING §4 explicitly permit this, provided the dependency is declared.
**Correct action**: Verify dependency is declared. If yes, file as compliant with an observation noting the Experimental exit condition.

### 7.4 Cross-document scope misapplication
**Pattern**: GUARDIAN applies a requirement from one document class to an artifact of a different class.
**Why wrong**: Requirements must be verified as applicable to the artifact type before being cited.
**Correct action**: Reject the finding.

### 7.5 Finding filed in multiple categories
**Pattern**: A finding appears in ❌ and is then softened with "non-blocking" inline, or appears in both ❌ and 💡.
**Why wrong**: Each finding belongs in exactly one category.
**Correct action**: Refile in the correct category.

### 7.6 Future-phase gaps raised as current-phase findings
**Pattern**: GUARDIAN flags missing Annex A catalog entry structure during Fast Track review.
**Why wrong**: Full catalog entry structure is a Step 7 output. Raising it as a gap at Step 6 is premature.
**Correct action**: Drop or note as observation only.

---

## 8. Acceptance criteria for GUARDIAN response

A GUARDIAN response is acceptable when:
1. Every ❌ finding has a literal citation that exists verbatim in the cited document
2. The cited requirement's stated scope covers the artifact type being evaluated
3. No finding appears in more than one category
4. No finding flags expected contribution behavior as a violation
5. No finding flags future-phase concerns as current-phase violations or gaps
6. 📋 Recommended actions references findings above rather than introducing new issues

---
