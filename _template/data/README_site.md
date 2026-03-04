# Cymatic K-Space Mechanics (CKS) Master Registry

**Status:** All constituent papers are locked and empirically falsifiable.  
**Framework Access:** `papers/{TOPIC}/{REGISTRY_ID}/manuscript.md`

## CKS: The Foundation Stack (Core Pillars)
*The mathematical and physical origin points of the CKS framework.*

| ID | Title | Description |
| :--- | :--- | :--- |
| **[[@CKS-0-2026]](papers/_CKS/CKS-0-2026/)** | **Root Axioms** | The $N=3M^2$ evolution law and the topological first split. |
| **[[@CKS-MATH-10-2026]](papers/MATH/CKS-MATH-10-2026/)** | **Grand Unification v1** | Complete Derivation of Physical Reality from Two Axioms |
| **[[@CKS-MATH-104-2026]](papers/MATH/CKS-MATH-104-2026/)** | **Grand Unification v23** | The Substrate Measurement Standard |

---
{% for topic in topics %}
## {{topic.topic}}: {{topic.title}}
*{{topic.subtitle}}*

| ID | Title | Description |
| :--- | :--- | :--- |
{% for paper in topic.papers %}| **[[@{{paper.paper_id}}]](papers/{{paper.subject}}/{{paper.paper_id}}/)** | **{{paper.title}}** | {{paper.subtitle}} |
{% endfor %}

---
{% endfor %}


*Every paper in this registry is a peer of the others. All derive from the Seed (CKS-0-2026).*

