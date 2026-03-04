# Cymatic K-Space Mechanics (CKS) Master Registry

**Status:** All constituent papers are locked and empirically falsifiable.  
**Framework Access:** `papers/{TOPIC}/{REGISTRY_ID}/manuscript.md`

---

{% for topic in topics %}
## {{topic.topic}}: {{topic.title}}
*{{topic.subtitle}}*

| ID | Title | Description |
| :--- | :--- | :--- |
| **[[@{register}]](papers/{TOPIC}/{register}/)** | **{title}** | {summary} |

---
{% endfor %}
