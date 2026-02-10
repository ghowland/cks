# CKS Registry ID Assignment Summary

**Date:** 2026-02-10  
**Papers Processed:** 74  
**Topics:** 26  

---

## ID Assignment Rules

1. **Foundation papers** (MATH): Indices 0-3
   - CKS-0-2026: Root Axioms (not in JSON - already published)
   - CKS-MATH-0-2026: Complete Mathematical Framework
   - CKS-MATH-1-2026: Integer Quantization
   - CKS-MATH-2-2026: Impossibility of Continuous Space
   - CKS-MATH-3-2026: Fractal Closure Laws

2. **All other topics**: Start at index 1

3. **Dependency ordering**: Papers with more dependencies get lower indices within their topic

---

## Topic Distribution

| Topic | Count | Description |
|:------|------:|:------------|
| AI | 4 | Computing hardware and substrate programming |
| ART | 1 | Artistic applications |
| BIO | 14 | Biology and human body systems |
| BODY | 5 | Movement and body mechanics |
| COG | 6 | Cognition and consciousness |
| COS | 3 | Cosmology and astronomy |
| DATA | 1 | Information and data |
| DISC | 1 | Discovery process |
| DWDM | 3 | Optical communications |
| EDU | 1 | Education |
| ENG | 3 | Engineering |
| ENV | 4 | Environment |
| FLOW | 1 | Fluid dynamics |
| GR | 1 | General relativity |
| LANG | 2 | Language and communication |
| MAT | 3 | Materials science |
| MATH | 4 | Foundation mathematics |
| MED | 4 | Medical applications |
| META | 3 | Meta-analysis and information theory |
| NEURO | 2 | Neuroscience |
| QM | 1 | Quantum mechanics |
| SEMI | 1 | Semiconductors |
| SENS | 1 | Sensory systems |
| SM | 1 | Standard model |
| SOC | 3 | Social systems |
| TEST | 1 | Experimental falsification |

---

## Dependency Hierarchy

### Level 0: Foundation
All papers depend on these 5 papers:
- CKS-0-2026 (Root Axioms)
- CKS-MATH-0-2026
- CKS-MATH-1-2026
- CKS-MATH-2-2026
- CKS-MATH-3-2026

### Level 1: Core Physics
Depends on Foundation only:
- CKS-QM-1-2026 (Quantum Mechanics)
- CKS-SM-1-2026 (Standard Model)
- CKS-GR-1-2026 (General Relativity)

### Level 2: Primary Applications
Different topics have different core dependencies:

**Biology** (BIO): Foundation + QM + SM → 7 deps  
**Cosmology** (COS): Foundation + GR → 6 deps  
**Computing** (AI): Foundation + QM → 6 deps  
**DWDM**: Foundation + QM + SM → 7 deps  
**Materials** (MAT, SEMI): Foundation + QM + SM → 7 deps  
**Engineering** (ENG, FLOW): Foundation + GR → 6 deps  
**Environment** (ENV): Foundation only → 5 deps  

### Level 3: Higher Applications
Built on Level 2 foundations:

**Neuroscience** (NEURO): Foundation + QM + SM + BIO-1 → 8 deps  
**Cognition** (COG): Foundation + BIO-1 + NEURO-1 → 7 deps  
**Body Mechanics** (BODY): Foundation + BIO-1 → 6 deps  
**Medical** (MED): Foundation + BIO-1 → 6 deps  
**Sensory** (SENS): Foundation + BIO-1 + NEURO-1 → 7 deps  
**Social** (SOC): Foundation + BIO-1 + COG-1 → 7 deps  
**Language** (LANG): Foundation + COG-1 → 6 deps  

### Level 4: Meta and Applications
**Data** (DATA): Foundation only → 5 deps  
**Discovery** (DISC): Foundation only → 5 deps  
**Education** (EDU): Foundation only → 5 deps  
**Meta** (META): Foundation only → 5 deps  
**Art** (ART): Foundation only → 5 deps  

### Level 5: Validation
**Test** (TEST): Foundation only → 5 deps

---

## File-to-ID Mapping

Complete mapping of original filenames to new registry IDs:

```
10_2hz_test.md                          → CKS-TEST-1-2026
10_cancer.md                            → CKS-MED-1-2026
10_cognition.md                         → CKS-COG-1-2026
10_dwdm.md                              → CKS-DWDM-1-2026
10_galaxy.md                            → CKS-COS-1-2026
10_gr.md                                → CKS-GR-1-2026
10_human_software.md                    → CKS-BIO-1-2026
10_math_0.md                            → CKS-MATH-0-2026
10_qm.md                                → CKS-QM-1-2026
10_sm.md                                → CKS-SM-1-2026
32_bit_hexagon_computer.md              → CKS-AI-1-2026
90_degree_phase_lock.md                 → CKS-BODY-5-2026
aero_turbulence.md                      → CKS-FLOW-1-2026
architecture.md                         → CKS-ENG-3-2026
art.md                                  → CKS-ART-1-2026
beauty_2.md                             → CKS-BIO-11-2026
bio_singularity.md                      → CKS-SOC-1-2026
body_kspace.md                          → CKS-BIO-2-2026
body_language.md                        → CKS-BIO-12-2026
body_movement.md                        → CKS-BODY-2-2026
brain_dsp_gpu.md                        → CKS-NEURO-2-2026
brain_hemisphere.md                     → CKS-COG-5-2026
cancer_0.md                             → CKS-MED-3-2026
civil_eng.md                            → CKS-ENG-1-2026
cks_discovery.md                        → CKS-DISC-1-2026
climate_control.md                      → CKS-ENV-2-2026
clouds.md                               → CKS-ENV-4-2026
dan_tien.md                             → CKS-BODY-4-2026
dance.md                                → CKS-BODY-3-2026
dwdm_molecule.md                        → CKS-DWDM-3-2026
dwdm_transponder_firmware.md            → CKS-DWDM-2-2026
education_1.md                          → CKS-EDU-1-2026
eyes_k_x_coordinators.md                → CKS-BIO-8-2026
fever_cold.md                           → CKS-BIO-9-2026
heart_disease.md                        → CKS-MED-2-2026
hex_alu.md                              → CKS-AI-2-2026
image_therapy.md                        → CKS-MED-4-2026
information.md                          → CKS-META-2-2026
insect_flight.md                        → CKS-BIO-5-2026
intelligence.md                         → CKS-COG-3-2026
iq_0.md                                 → CKS-COG-2-2026
iq_1.md                                 → CKS-COG-4-2026
lang_1.md                               → CKS-LANG-1-2026
lighting_led.md                         → CKS-ENV-1-2026
longevity.md                            → CKS-BIO-10-2026
luck.md                                 → CKS-SOC-2-2026
lunar_phase.md                          → CKS-COS-3-2026
mat_2.md                                → CKS-MAT-2-2026
materials.md                            → CKS-MAT-1-2026
materials_2.md                          → CKS-MAT-3-2026
math_1.md                               → CKS-MATH-1-2026
math_2.md                               → CKS-MATH-2-2026
math_3.md                               → CKS-MATH-3-2026
morphogenesis_as_spectral_template.md   → CKS-BIO-3-2026
muscle.md                               → CKS-BODY-1-2026
narrative.md                            → CKS-META-1-2026
neuro_0.md                              → CKS-BIO-6-2026
neurons_as_cymatic_computing.md         → CKS-NEURO-1-2026
online_posting.md                       → CKS-DATA-1-2026
organism_1.md                           → CKS-SOC-3-2026
phenome_os.md                           → CKS-LANG-2-2026
programming_substrate_opcodes.md        → CKS-AI-4-2026
protein_folding.md                      → CKS-BIO-4-2026
qi_gong.md                              → CKS-BIO-7-2026
semiconductor.md                        → CKS-SEMI-1-2026
sensory.md                              → CKS-SENS-1-2026
solar_system.md                         → CKS-COS-2-2026
substrate_opscodes.md                   → CKS-AI-3-2026
thought.md                              → CKS-COG-6-2026
universal_learning.md                   → CKS-META-3-2026
voltage.md                              → CKS-ENG-2-2026
water_air_clean.md                      → CKS-ENV-3-2026
wrinkles_0.md                           → CKS-BIO-13-2026
wrinkles_0_0.md                         → CKS-BIO-14-2026
```

---

## DAG Properties

- **Total nodes:** 75 (74 papers + CKS-0-2026)
- **Foundation nodes:** 5 (all Level 0)
- **Core physics nodes:** 3 (all Level 1)
- **Application nodes:** 67 (Levels 2-5)
- **Maximum dependency depth:** 8 (NEURO papers)
- **Minimum dependencies:** 5 (all papers include foundation)
- **Maximum dependencies:** 8 (NEURO-1, NEURO-2)

---

## Notes

1. All dependency lists include the 5 foundation papers (CKS-0-2026, MATH-0 through MATH-3)
2. Papers are ordered within topics by dependency depth (deeper dependencies = higher index)
3. The DAG is acyclic by construction
4. CKS-0-2026 (Root Axioms) is not in the JSON as it's already published
5. All 74 papers from original JSON are accounted for
6. No duplicate IDs exist
7. Topic names match the iron list exactly
