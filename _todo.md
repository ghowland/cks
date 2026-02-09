Based on the JSON collection provided, here is the comprehensive enumeration of requirements for every paper in the CKS framework. I have divided these into **Foundational Requirements** (those needing to be registered/formatted) and **Dependency Requirements** (the logical links).

### 1. Root & Foundational Requirements - Hallucinations to be fixed

These papers are missing formal `registry_id` or `series_path` metadata in their JSON, yet they are cited as prerequisites for others.

*   **[CKS-BIO-1-2026]**: Must be finalized and formally linked to `human_as_software_defined_matter.md`.
*   **[CKS-MATH-3-2026]**: `math_3.md` needs to be formally indexed as the regulator for scaling laws.
*   **[CKS-ELEC-1-2026]**: Required by `hex_alu.md` and `mat_2.md`. *Status: Not found in JSON file list.*
*   **[CKS-BIO-11.2-2026]**: Required by `architecture.md`, `body_language.md`, `fever_cold.md`, and `longevity.md`. *Status: Missing.*
*   **[CKS-BIO-9.4-2026]**: Required by `brain_dsp_gpu.md`, `dan_tien.md`, `dance.md`, and `luck.md`. *Status: Missing.*
*   **[CKS-LANG-9-2026]**: Formalizing the "Phonemic OS" in `phenome_os.md`.

---

### 2. Individual Paper Requirements (The Application Stack)

#### **Computational & Industrial Tier**
*   **32-Bit Hexagon Computer (`32_bit_hexagon_computer.md`)**
    *   Requirement: Assign `[CKS-COMP-1-2026]`.
    *   Path: `[CKS-0] → [CKS-MATH-1] → [CKS-COMP-1]`.
*   **Substrate Programming Language (`programming_substrate_opcodes.md`)**
    *   Requirement: Assign `[CKS-COMP-2-2026]`.
    *   Requirement: Resolve reference to `[CKS-MATH-6.3-2026]`.
*   **Substrate-Harmonized DWDM (`dwdm_transponder_firmware.md`)**
    *   Requirement: Assign `[CKS-DWDM-2-2026]`.
    *   Path: `[CKS-DWDM-1] → [CKS-DWDM-2]`.
*   **AI Embodiment (`ai_body.md`)**
    *   Requirement: Assign `[CKS-AI-1-2026]`.
    *   Requirement: Resolve reference to `[CKS-INSECT-1-2026]` (Biological Flight).

#### **Biological Tier ([CKS-BIO])**
*   **Harmonic Organism (`body_kspace.md`)**
    *   Requirement: Resolve dependency on `[CKS-ASTRO-5-2026]` (Lunar Phase).
*   **Amphibian/Limb Regeneration (`organism_1.md`)**
    *   Requirement: Formally link to `[CKS-BIO-2-2026]`.
*   **Insect Flight (`insect_flight.md`)**
    *   Requirement: Assign `[CKS-BIO-4-2026]`.
    *   Dependencies: `[CKS-MAT-1]` and `[CKS-TEST-1]`.
*   **Longevity Engineering (`longevity.md`)**
    *   Dependencies: `[CKS-BIO-11]`, `[CKS-BIO-15]`, `[CKS-BIO-16]`.

#### **Medical Tier ([CKS-MED])**
*   **Heart Disease (`heart_disease.md`)**
    *   Requirement: Assign `[CKS-MED-2-2026]`.
    *   Path: `[CKS-BIO-1] → [CKS-MATH-3] → [CKS-MED-2]`.
*   **Morphogenesis (`morphogenesis_as_spectral_template.md`)**
    *   Requirement: Assign `[CKS-MED-3-2026]`.
*   **Image-Based Coherence Therapy (`image_therapy.md`)**
    *   Requirement: Assign `[CKS-MED-5-2026]`.

#### **Cognitive Tier ([CKS-COG])**
*   **Intelligence/IQ (`intelligence.md` / `iq_1.md`)**
    *   Requirement: IQ Bandwidth Theory must resolve to `[CKS-COG-2-2026]`.
    *   Path: `[CKS-COG-1] → [CKS-COG-2]`.
*   **Neurons as Cymatic Computing (`neurons_as_cymatic_computing.md`)**
    *   Requirement: Assign `[CKS-NEURO-1-2026]`.
    *   Path: `[CKS-BIO-1] → [CKS-MATH-1] → [CKS-NEURO-1]`.

---

### 3. Missing Links & Circular Ref Risks
The JSON scan revealed several references to papers that do not yet exist in your file list. To ensure **Mathematical Sovereignty**, these must be created or the references redirected:
1.  **[CKS-BIO-15.1]**: Heavy dependency for `brain_dsp_gpu.md` and `phenome_os.md`.
2.  **[CKS-MATH-6.1 / 6.2 / 6.3]**: These appear to be the "Compiler Level" math proofs required for the computation tier.
3.  **[CKS-PLAN-2.1 / 2.3]**: Required for the environmental irrigation/climate papers.
4.  **[CKS-ASTRO-4 / 4.4]**: Required for the Lunar Phase proof.
5.  **[CKS-COCREATE-1]**: The meta-paper for the AI-Human collaboration process.

---

### 4. Summary of "Null" Registry IDs
The following files **must be opened and updated** with a `**Registry:**` and `**Series Path:**` immediately to fix the JSON "null" values:
*   `32_bit_hexagon_computer.md`
*   `ai_body.md`
*   `art.md`
*   `bio_singularity.md`
*   `body_kspace.md`
*   `body_movement.md`
*   `civil_eng.md`
*   `climate_control.md`
*   `dwdm_molecule.md`
*   `dwdm_transponder_firmware.md`
*   `heart_disease.md`
*   `image_therapy.md`
*   `information.md`
*   `insect_flight.md`
*   `intelligence.md`
*   `iq_1.md`
*   `materials.md`
*   `materials_2.md`
*   `morphogenesis_as_spectral_template.md`
*   `neurons_as_cymatic_computing.md`
*   `programming_substrate_opcodes.md`
*   `protein_folding.md`
*   `semiconductor.md`
*   `solar_system.md`
*   `substrate_opscodes.md`
*   `voltage.md`
*   `water_air_clean.md`

### Final Order:
I will await your command to generate the **Pillar Proof** text for any of these. Which one shall we fix first?
