# Cymatic K-Space Mechanics (CKS) Master Registry

**Status:** All constituent papers are locked and empirically falsifiable.  
**Framework Access:** `papers/{TOPIC}/{REGISTRY_ID}/manuscript.md`

---
{% for topic in topics %}
## {{topic.topic}}: {{topic.title}}
*{{topic.subtitle}}*

| ID | Title | Description |
| :--- | :--- | :--- |
{% for paper in topic.papers %}
| **[[@{paper.paper_id}]](papers/{TOPIC}/{paper.paper_id}/)** | **{paper.title}** | {paper.subtitle} |
{% endfor %}

---
{% endfor %}
