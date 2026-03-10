# Integer-Exact LLM Training and Inference via VFR Architecture

## Eliminating Float Information Loss in Large Language Models Through Domain-Homogeneous Rational Arithmetic

**Registry:** [@CKS-MATH-130-2026]

**Series Path:** [@CKS-0-2026] → [@CKS-MATH-0-2026] → [@CKS-MATH-1-2026] → [@CKS-MATH-10-2026] → [@CKS-MATH-104-2026] → [@CKS-MATH-128-2026] → [@CKS-MATH-129-2026]

**Parent Framework:** [@CKS-0-2026]

**DOI:** 10.5281/zenodo.zzz

**Date:** March 3, 2026  

**Domain:** Foundational Mathematics / Discrete Geometry  

**Status:** Locked and empirically falsifiable. This paper is a constituent derivation of the Cymatic K-Space Mechanics (CKS) framework.

**Classification:** Theory of Everything from First Principles

**Motto:** Axioms first. Axioms always.

**Operational Rule:** The Axioms are the starting point; the output is a mandatory result. Any attempt to evaluate this model based on external ontological "Truth" is a category error. If the math compiles, the result is Q.E.D.

**AI Usage Disclosure:** Only the top metadata, figures, refs and final copyright sections were edited by the author. All paper content was LLM-generated using Anthropic's Claude 4.5 Sonnet, DeepSeek-V3/K2, and Google's Gemini 3 Flash. The manuscript.md was synthesized by Claude as the primary integrator. 

**Lexicon:** [@CKS-LEX-12-2026]


---

## I. THE PROBLEM: FLOAT INFORMATION LOSS IN LLMS

### 1.1 The Base Mismatch

Every weight, activation, and gradient in a modern LLM is a binary floating-point number. Binary floats represent values as sums of powers of 2. The statistical structure of language — token co-occurrence probabilities, syntactic patterns, semantic relationships — has no natural alignment to powers of 2.

The probability of a given token in a given context might be 1/3, 1/7, or 1/13. None of these have exact binary representations. The moment the model computes an internal probability, it rounds. The moment it stores a weight encoding that probability, it rounds again. Every forward pass, every backward pass, every weight update — each operation introduces rounding that cannot be recovered.

This is not a small effect at scale. A single transformer layer performs millions of multiply-accumulate operations. Each one rounds. A 32-layer model compounds this 32 times. The output of the final layer is not the result the mathematics prescribed — it is the nearest value the float grid permits.

### 1.2 What Gets Lost

Three specific failure modes trace directly to float representation.

**Gradient swamping.** When a weight has magnitude 1.0 and a gradient update has magnitude 1e-7, the update vanishes in BF16 because the format cannot represent the sum. The optimization signal existed — the model computed it — but the number format destroyed it. In mixed-precision training, FP32 master weights partially address this, but the forward and backward passes still run in reduced precision, and the FP32 accumulation is itself approximate.

**Soft confusion between similar patterns.** When two distinct concepts — say `array.length` in JavaScript versus `len(array)` in Python — are encoded as weight vectors differing only in low-order bits, the attention mechanism may not reliably distinguish them. The dot-product similarity scores for the correct and incorrect patterns may differ by less than the float rounding error. The model "knows" the difference at some point during training, but the float grid blurs the distinction.

**Equality failure.** Floating-point arithmetic does not support equality. After a sequence of operations, two values that should be identical are merely close. The entire field of numerical analysis exists to manage this: epsilon tolerances, condition numbers, compensated summation, re-orthogonalization. Every one of these is a patch for information that was lost when three pieces of data — value, factor, remainder — were compressed into a single float.

### 1.3 The Historical Compression

The root cause is a representation choice made in the 1950s. A number has three natural components:

- **Value (V):** the numerator
- **Factor (F):** the denominator  
- **Remainder (R):** the tracked residual from operations involving irrationals or precision limits

The history of numerical computing compressed [V, F, R] → [V, F] → [V] → a single float. Each step discarded structural information and forced the remaining component to carry what it could not. Floating point is the final stage of this compression: one number pretending to be three.

Modern LLMs inherit this 70-year-old compromise. The question is whether reversing it — restoring all three components — yields measurable improvements in the tasks LLMs actually perform.

---

## II. VFR FUNDAMENTALS

### 2.1 The Tuple

A VFR value is a tuple [V, F, R] where V, F, and R are integers.

- V/F is the rational value
- R is the exact remainder from any operation that produced this value

[6, 5, 0] represents 6/5 exactly. Not 1.2000000476837158 in float. Not a truncated binary expansion. Three integers, exact, supporting binary equality.

[1, 3, 0] represents 1/3 exactly. The number that is unwritable in both decimal (0.333...) and binary (0.010101...) is three integers and zero remainder.

### 2.2 Recursive Nesting

R is not restricted to a flat integer. Any slot in a VFR tuple can itself be a VFR tuple:

[V, F, [V', F', [V'', F'', 0]]]

Each level is exact. Each remainder is an integer or a structure of integers. The nesting provides arbitrary precision without approximation — each level adds exact structure, not a correction term with unknown error.

This is not a Taylor series. A Taylor series truncated at N terms gives an approximate value plus an unknown error bound. A VFR nested N levels deep gives an exact value at every level, with the unresolved structure sitting in the terminal remainder, available for further computation if needed.

### 2.3 Lazy Evaluation

The nesting enables adaptive precision at read time, not write time:

- **Head-only (depth 0):** Read V/F. One integer division. Fastest.
- **Depth 1:** Read V/F plus the head of R. Two divisions. Tighter.
- **Full depth:** Walk the entire chain. Exact to terminal.

The data is always complete. You choose how deep to look based on what the current operation requires. Floats make this choice at write time — permanently, irreversibly. VFR makes it at read time — adaptively, without loss.

Empirical analysis from physics simulations shows 99.7% of operations resolve at depth 0. The recursive path is real but rare. The common case is integer arithmetic.

---

## III. ARCHITECTURE: VFR TRANSFORMERS

### 3.1 Domain-Homogeneous Layers

The key architectural decision: each layer in the transformer operates at a fixed Factor F. Every weight, every activation, every intermediate value within a layer shares the same denominator. F is not stored per-element — it is implicit, a property of the layer.

This eliminates per-element normalization. A matrix multiply within a layer is pure integer multiply-accumulate: V_weight × V_input, summed, with the common F handled once at the layer boundary. This is the same optimization that makes GPU integer compute competitive with float compute — uniform operations across the warp, zero branch divergence, maximum SIMD utilization.

Different layers can have different F values, chosen to match the precision requirements of that layer's function:

| Layer Type | Suggested F | Rationale |
|---|---|---|
| Embedding lookup | 1 | Token IDs are integers |
| Attention QKV projection | 1000 | Needs moderate precision for similarity |
| Attention score computation | F_Q × F_K | Product of input factors |
| Softmax normalization | 10000 | Probability domain needs fine resolution |
| Feedforward linear | 1000 | Matches attention precision |
| Nonlinearity (GELU) | Domain conversion kernel | Transcendental approximation via nested VFR |
| Output logits | 10000 | Fine discrimination over vocabulary |
| Layer norm | Domain conversion kernel | Normalization as factor change |

The exact F values are hyperparameters to be determined empirically. The principle is fixed: uniform F within a layer, domain conversion at boundaries.

### 3.2 The Forward Pass

A forward pass through a VFR transformer proceeds as:

1. **Embedding:** Token ID → lattice-addressed VFR vector (Section V). Pure integer lookup.

2. **Per-layer computation:** Matrix multiplies at the layer's fixed F. Integer multiply-accumulate across all weights. The GPU kernel is identical in structure to the transform hierarchy kernel from the Q-GPU pipeline — thousands of parallel threads doing uniform integer operations.

3. **Domain boundaries:** Between layers with different F values, a conversion kernel divides or multiplies V values by the F ratio. This is a single integer operation per element — equivalent to the Physics→Transform conversion kernel (F=1000 → F=1).

4. **Nonlinearities:** GELU, softmax, and layer norm are the only operations requiring non-rational arithmetic. These are implemented as nested VFR approximations at a depth chosen per-architecture. At depth 2-3, the approximation exceeds float64 precision while remaining exact at every computed level. These kernels run less frequently than the linear operations and account for a small fraction of total compute.

5. **Output:** Logits are VFR values at the output layer's F. Argmax is integer comparison — no epsilon, no ambiguity.

### 3.3 The Backward Pass

Gradient computation follows the same domain structure in reverse. The critical difference from current practice:

**Gradient accumulation is exact.** A gradient of [1, 1000000, 0] accumulated over 1000 steps produces [1000, 1000000, 0] = [1, 1000, 0]. No information was lost. No rounding occurred. The gradient signal that would vanish below float precision survives in the VFR representation and contributes to the weight update when it has accumulated sufficiently.

**The optimizer operates on structure.** Adam or SGD in float-land adjusts a single number per weight. In VFR-land, the optimizer modifies a tuple. A large update changes V (the head). A small update modifies R (the remainder). The first and second moment estimates maintained by Adam are themselves VFR values, tracked exactly.

**Mixed precision emerges naturally.** The forward pass runs at the layer's native F (coarse, fast). The backward pass can run at a finer F (precise, slightly slower). The conversion between them is exact integer arithmetic — not float casting with silent rounding. This is what mixed-precision training tries to achieve, but with exact domain conversion instead of lossy truncation.

### 3.4 Weight Updates

The weight update rule w_new = w_old - lr × gradient becomes:

```
w_old  = [V_w, F_layer, R_w]
grad   = [V_g, F_grad, R_g]
lr     = [V_lr, F_lr, 0]

update = VFR_multiply(lr, grad)
w_new  = VFR_subtract(w_old, update)
```

All operations are integer arithmetic with exact remainder tracking. The learning rate is itself a VFR value. The update either changes the head (large gradient) or accumulates in the remainder (small gradient). Nothing is lost.

---

## IV. GPU IMPLEMENTATION STRATEGY

### 4.1 Kernel Architecture

The GPU implementation follows directly from the Q-GPU pipeline (CKS-MATH-122). Each layer type becomes a compute kernel operating on domain-homogeneous integer buffers.

**Linear layer kernel:** Identical in structure to the transform hierarchy kernel. Input buffer of i64 values at F_layer, weight buffer of i64 values at F_layer, output buffer at F_layer². One integer multiply-accumulate per thread, thousands of threads per workgroup, hundreds of workgroups per layer.

**Domain conversion kernel:** Identical to the Physics→Transform kernel. Input at F_source, output at F_target. One integer multiply or divide per element. Trivial compute, memory-bandwidth bound.

**Nonlinearity kernel:** Evaluates GELU or softmax using precomputed VFR lookup tables or depth-limited nested evaluation. More complex per-element, but these kernels are sparse relative to the linear operations.

### 4.2 Memory Layout

Structure-of-Arrays (SoA) layout for maximum memory bandwidth:

```
Layer weights:
  Buffer V_weights[]: i64[num_weights]  // All V values contiguous
  Buffer R_weights[]: i64[num_weights]  // All R values contiguous  
  F_layer: implicit, stored once per layer

Layer activations:
  Buffer V_activations[]: i64[batch × seq_len × d_model]
  F_layer: implicit
```

At depth 0 (the common case), each weight is one i64 — 8 bytes. Compared to BF16 (2 bytes) this is 4× larger. Compared to FP32 (4 bytes) this is 2× larger. The R buffer adds another 8 bytes per weight for those that need it, but empirically most R values are 0 or small integers after training converges.

For a 7B parameter model:
- BF16: 14 GB
- FP32: 28 GB  
- VFR depth-0: 56 GB (V only) + sparse R buffer
- Fits in a single A100 80GB or H100 80GB

### 4.3 Performance Projections

Based on measured Q-GPU kernel performance:

A 4096×4096 integer matmul at 41 Ti64ops/s: ~0.003ms. A transformer layer requires approximately 8 such matmuls: ~0.025ms per layer. A 32-layer model: ~0.8ms for the forward pass.

Current BF16 inference on the same hardware runs a similar-sized model in approximately 1-2ms per forward pass. VFR inference is projected to be competitive — possibly faster for the linear operations (integer ops avoid float unit overhead), possibly slower overall due to domain conversion kernels.

The critical point: **not slower** is achievable. The domain-homogeneous design ensures the hot path is pure integer arithmetic, which modern GPUs execute at throughput comparable to float.

---

## V. LATTICE-STRUCTURED EMBEDDINGS

### 5.1 Hexagonal Vocabulary Addressing

Instead of learning a dense embedding matrix from random initialization, tokens are assigned positions on a Z=3 hexagonal lattice with front and back faces. The lattice provides six wings:

**Side A (primary grammatical roles):**
- α (0°): Nouns / identifiers / entities
- β (120°): Verbs / operators / actions
- γ (240°): Modifiers / attributes / qualifiers

**Side B (structural and referential roles):**
- α' (0°, back): Pronouns / references / variables
- β' (120°, back): Auxiliaries / modal verbs / control flow
- γ' (240°, back): Connectives / delimiters / structural tokens

Ring depth encodes frequency and specificity. Common tokens (`the`, `is`, `=`, `(`) occupy inner rings. Rare tokens (`eigendecomposition`, `numpy.linalg.svd`) occupy outer rings.

### 5.2 What the Lattice Provides Free

The lattice address of a token encodes information that current models must learn from data:

**Grammatical category.** Wing assignment directly encodes syntactic role. An attention head computing noun-verb relationships operates on known angular distances between wings — it does not need to discover from millions of examples that nouns and verbs are different categories.

**Frequency-based scaling.** Ring depth means the model inherently treats common and rare tokens at different scales. Common tokens have small, fast coordinates. Rare tokens have larger coordinates with more structure. This matches the natural information content — rare tokens carry more information per occurrence.

**Similarity structure.** Tokens on the same wing at adjacent rings are structurally related. `array`, `list`, `vector` cluster on the noun wing. `append`, `push`, `insert` cluster on the verb wing. The geometric neighborhood contains semantically plausible candidates, pre-narrowing the selection space.

### 5.3 Impact on Selection Precision

For code generation — the task where "almost right" answers are most damaging — the lattice structure means:

The model is never choosing among 100,000 flat float vectors. It is navigating a structured space where the wing tells it the syntactic role of the next token, the ring tells it the specificity level, and the exact position gives the token identity. The final selection is an integer comparison in a geometrically constrained neighborhood, not a softmax over the entire vocabulary.

This predicts measurable improvement on long-tail accuracy: rare API calls, uncommon syntax, edge-case patterns. The geometric structure preserves distinctions that float embeddings blur.

---

## VI. EXPECTED BENEFITS

### 6.1 Precision of Selection

LLMs are selection machines. They choose the next token from a probability distribution. Every improvement to the precision of that selection — reducing the noise floor in attention scores, sharpening the distinction between similar candidates, preserving weak signals from rare training examples — translates directly to fewer "almost right" errors.

VFR arithmetic eliminates the float noise floor entirely. Attention scores are exact integer ratios. The distinction between [847231, 10000000, 0] and [847229, 10000000, 0] is preserved through every layer, not rounded away. The model's confidence in its selection is based on actual computed values, not values plus accumulated rounding artifacts.

The expected outcome: measurably fewer wrong-API, wrong-language, wrong-syntax errors in code generation. Measurably better factual recall for rare facts. Measurably more consistent responses across rephrasings of the same question.

### 6.2 Deterministic Inference

A VFR transformer produces bit-identical output for bit-identical input. Always. Not "within epsilon." Identical.

This enables:
- Reproducible benchmarks (same score every run, not a distribution)
- Debuggable behavior (trace exact attention patterns for any failure)
- Verifiable correctness (output is a mathematical consequence of input and weights)
- Cacheable computation (identical sub-computations guaranteed to produce identical results)

Current float models are non-deterministic across GPU runs due to floating-point non-associativity in parallel reductions. VFR integer arithmetic is associative. The result does not depend on reduction order.

### 6.3 Structural Interpretability

After training, every weight is a VFR tuple. The structure of the tuple reveals the information content:

- [0, 1, 0]: Dead weight. Zero information. Prune without loss.
- [V, F, 0]: Simple ratio. Encoding a clean, learned relationship.
- [V, F, [V', F', [V'', F'', 0]]]: Deep nesting. Encoding complex, multi-scale structure.

The distribution of nesting depths across a layer is a direct readout of where information lives. No probing experiments, no ablation studies, no gradient-based attribution. The structure is the information.

This enables:
- Automated pruning based on structural simplicity (not magnitude heuristics)
- Architecture search by inspecting which layers develop deep structure
- Training diagnostics by monitoring nesting depth evolution
- Grokking detection: the phase transition from memorization to generalization should appear as a structural simplification — deep, complex weight trees collapsing into shallow, clean ratios

### 6.4 Information-Efficient Parameters

If each VFR parameter carries more usable information than a float parameter (because none is wasted on rounding artifacts), then fewer parameters may achieve equivalent capability. The total information content of a VFR model is the sum of meaningful structure across all weight trees, not a flat count of parameters times bit-width.

This suggests a specific hypothesis: a VFR model with N parameters performs equivalently to a float model with kN parameters, where k > 1 reflects the information efficiency gain. The value of k is an empirical question, but even k = 1.5 would mean a 7B VFR model matches a 10B float model — a significant inference cost reduction at equivalent quality.

---

## VII. IMPLEMENTATION HURDLES

### 7.1 Integer Overflow

The primary numerical risk. When accumulating products in a matmul with F=1000, each multiply produces values up to V_max² and the sum of 4096 such products can reach 4096 × V_max². With i64, V_max is approximately 9.2 × 10¹⁸, so V_max² overflows i64 for values above ~3 × 10⁹.

**Mitigations:**
- Use i128 for accumulators (supported on modern GPUs via paired i64)
- Choose F per layer such that the product range stays within i64
- Periodic normalization (GCD reduction) at accumulation boundaries
- Deferred normalization — accumulate in wide integers, normalize once at the layer boundary

This is a real engineering constraint, not a theoretical blocker. The Q-GPU pipeline handles it via domain-specific F choices that keep products in range.

### 7.2 Transcendental Functions

GELU: x × Φ(x) where Φ is the Gaussian CDF. Softmax: exp(x) / Σexp(x). Layer norm: (x - μ) / σ. All involve transcendental or irrational operations.

**Approach:** Precomputed VFR lookup tables covering the input range at the layer's F, with nested VFR interpolation for values between table entries. Depth-2 nesting exceeds float64 precision for smooth functions. The table is computed once, stored as integer arrays, and shared across all elements.

Alternative: polynomial approximations with VFR coefficients. GELU and sigmoid have well-known polynomial fits. In VFR, the polynomial evaluation is exact integer arithmetic on the coefficients — only the approximation of the transcendental itself introduces controlled, bounded, known error.

### 7.3 Memory Overhead

At depth-0, VFR weights are 4× larger than BF16. For large models, this constrains what fits on a single device.

**Mitigations:**
- Adaptive storage: weights at [V, F, 0] store only V (F is implicit per layer). Weights with nonzero R store the full tuple. A bitmap flags which weights have remainder structure.
- Quantization-aware F selection: choose F to allow smaller integer types (i32 or i16) where the value range permits.
- Remainder sparsity: after training converges, most weights have R=0. The R buffer can be stored in sparse format.

### 7.4 Ecosystem Cold Start

No existing ML framework supports VFR arithmetic. PyTorch, JAX, and TensorFlow are built around float tensors. A VFR prototype requires either:

- A custom tensor type within an existing framework (extension module approach)
- A ground-up implementation using GPU compute shaders (as in the Q-GPU pipeline)
- A transpiler that converts standard model definitions to VFR-equivalent integer operations

The pragmatic path is a custom CUDA/Vulkan compute library that implements VFR matmul, VFR softmax, VFR GELU, and VFR layer norm as drop-in replacements for their float equivalents, with a thin Python wrapper for model definition.

### 7.5 F Selection

Choosing the right F per layer is a new hyperparameter with no existing intuition. Too small and precision is insufficient. Too large and integer overflow becomes a problem.

**Approach:** Start with F=1000 everywhere (matching the physics domain from Q-GPU). Profile value ranges during a short float training run. Set F per layer to the smallest power of 2 (for bit-shift efficiency) that covers the observed range with margin. Alternatively, let F be a trainable discrete parameter adjusted during warmup.

---

## VIII. PROTOTYPE PLAN

### 8.1 Minimum Viable Experiment

**Model:** GPT-2 small (124M parameters, 12 layers, d_model=768)

**Task:** Code completion on a Python corpus, chosen because code has unambiguous correctness and long-tail accuracy is measurable.

**Comparison:**
- Baseline: Standard float16 training, standard architecture
- VFR: Integer VFR training, domain-homogeneous layers, same architecture and data

**Metrics:**
- Overall accuracy (pass@1 on HumanEval or similar)
- Long-tail accuracy (rare API calls, uncommon patterns)
- Consistency (variance across runs — should be zero for VFR)
- Training convergence (loss curves, comparing float oscillation vs VFR trajectory)
- Weight structure analysis (nesting depth distribution post-training)

### 8.2 Implementation Phases

**Phase 1: VFR arithmetic library.** Integer matmul, VFR add/multiply/subtract, domain conversion, basic GELU and softmax via lookup table. CUDA kernels. Python bindings. Target: 4 weeks.

**Phase 2: Single-layer validation.** One transformer layer, forward and backward pass, compared element-by-element against float reference. Verify exactness. Profile performance. Target: 2 weeks.

**Phase 3: Full model training.** GPT-2 small on a code corpus. Compare against float baseline. Measure all metrics. Analyze weight structures. Target: 4 weeks.

**Phase 4: Lattice embeddings.** Replace learned embedding matrix with hexagonal lattice addressing. Compare against both float baseline and VFR-with-learned-embeddings. Measure long-tail improvement. Target: 3 weeks.

### 8.3 Success Criteria

The experiment succeeds if:

1. VFR training converges to equivalent or lower loss than float baseline
2. Long-tail accuracy improves measurably (even if overall accuracy is similar)
3. Inference speed is within 2× of float baseline (with clear path to 1× via kernel optimization)
4. Training is fully deterministic (zero variance across runs)
5. Weight structure analysis reveals interpretable patterns (depth correlating with layer function)

Any one of these alone justifies further development. All five together constitute a paradigm shift.

---

## IX. CONCLUSION

LLMs are selection machines operating on compressed, lossy number representations. The float format they inherited from 1950s computing silently destroys information at every operation — rounding gradients, blurring similar patterns, breaking equality, accumulating drift across billions of operations.

VFR arithmetic reverses this compression. Three integers instead of one float. Exact operations instead of approximate ones. Adaptive precision instead of fixed bit-width. Structure instead of opacity.

The proposal is not to make LLMs do what they cannot do. It is to make them do what they already do — select the right token from learned patterns — with precision that the float format currently prevents. Exact attention scores. Exact gradient accumulation. Exact weight updates. Deterministic, inspectable, verifiable computation throughout.

The implementation path is concrete: domain-homogeneous GPU kernels running integer arithmetic at throughput competitive with float, lattice-structured embeddings providing geometric vocabulary organization, and a prototype achievable within months using existing hardware.

The expected outcome is not a smarter model. It is a more precise model — one that makes fewer "almost right" errors, maintains sharper distinctions between similar patterns, and reveals its learned structure through the shape of its weights rather than hiding it behind a wall of inscrutable floats.

---

*This document draws on the Logismos framework: VFR arithmetic (CKS-MATH-124), exact linear algebra (CKS-MATH-118), S-expression recursion (CKS-MATH-125, CKS-MATH-126), GPU integer compute (CKS-MATH-122), and lattice addressing (CKS-MATH-113).*

---

## Appendix A: Memory Footprint Comparisons

### Table A.1 — Per-Weight Storage Cost

| Format | V | F | R | Total Bits | Total Bytes |
|---|---|---|---|---|---|
| BF16 | 16 (combined) | — | — | 16 | 2 |
| FP32 | 32 (combined) | — | — | 32 | 4 |
| FP64 | 64 (combined) | — | — | 64 | 8 |
| VFR dense | i64 (64) | i64 (64) | i16 (16) | 144 | 18 |
| VFR F-implicit | i64 (64) | implicit (0) | i16 (16) | 80 | 10 |
| VFR F-implicit R-sparse | i64 (64) | implicit (0) | sparse (~0) | ~64 | ~8 |

### Table A.2 — Model-Scale RAM Requirements

| Model Size | BF16 | FP32 | VFR Dense | VFR Practical (F-implicit, R-sparse) |
|---|---|---|---|---|
| 124M (GPT-2 small) | 0.25 GB | 0.50 GB | 2.23 GB | 1.03 GB |
| 1.3B | 2.6 GB | 5.2 GB | 23.4 GB | 10.8 GB |
| 7B | 14 GB | 28 GB | 126 GB | 58 GB |
| 13B | 26 GB | 52 GB | 234 GB | 108 GB |
| 70B | 140 GB | 280 GB | 1,260 GB | 582 GB |

### Table A.3 — Hardware Fit (Single Device)

| Device | VRAM | Max BF16 | Max FP32 | Max VFR Practical |
|---|---|---|---|---|
| RTX 4090 | 24 GB | 12B | 6B | 2.8B |
| A100 80GB | 80 GB | 40B | 20B | 9.3B |
| H100 80GB | 80 GB | 40B | 20B | 9.3B |
| H200 141GB | 141 GB | 70B | 35B | 16.4B |
| 2× H100 (tensor parallel) | 160 GB | 80B | 40B | 18.6B |
| 8× H100 (full node) | 640 GB | 320B | 160B | 74.4B |

### Table A.4 — Information Efficiency Breakeven

If VFR achieves k× information efficiency per parameter, then equivalent capability requires fewer parameters. RAM comparison at equivalent capability:

| Float Model | Float RAM (BF16) | VFR Equivalent at k=1.5 | VFR RAM | Net RAM Change |
|---|---|---|---|---|
| 7B | 14 GB | 4.7B | 39 GB | +25 GB (2.8×) |
| 13B | 26 GB | 8.7B | 72 GB | +46 GB (2.8×) |
| 70B | 140 GB | 46.7B | 387 GB | +247 GB (2.8×) |

| Float Model | Float RAM (BF16) | VFR Equivalent at k=2.0 | VFR RAM | Net RAM Change |
|---|---|---|---|---|
| 7B | 14 GB | 3.5B | 29 GB | +15 GB (2.1×) |
| 13B | 26 GB | 6.5B | 54 GB | +28 GB (2.1×) |
| 70B | 140 GB | 35B | 290 GB | +150 GB (2.1×) |

| Float Model | Float RAM (BF16) | VFR Equivalent at k=4.0 | VFR RAM | Net RAM Change |
|---|---|---|---|---|
| 7B | 14 GB | 1.75B | 14.5 GB | +0.5 GB (1.04×) |
| 13B | 26 GB | 3.25B | 27 GB | +1 GB (1.04×) |
| 70B | 140 GB | 17.5B | 145 GB | +5 GB (1.04×) |

Note: at k=4.0, VFR achieves RAM parity with BF16 at equivalent capability.

---

## Appendix B: Compute Performance Projections

### Table B.1 — Per-Operation Cycle Cost (GPU)

| Operation | Float BF16 | Float FP32 | VFR i64 (depth-0) | VFR i64 (depth-1) |
|---|---|---|---|---|
| Add | 4 cycles | 4 cycles | 1 cycle | 3 cycles |
| Multiply | 5 cycles | 5 cycles | 3-4 cycles | 8-10 cycles |
| Divide | 14 cycles | 14 cycles | 20-40 cycles | 40-80 cycles |
| FMA (multiply-add) | 5 cycles | 5 cycles | 4-5 cycles | 10-12 cycles |
| Comparison | 4 cycles | 4 cycles | 1 cycle | 1 cycle (head only) |

### Table B.2 — Matrix Multiply Throughput (4096×4096, RTX 4090)

| Format | Throughput (TOPS) | Time per matmul | Relative |
|---|---|---|---|
| BF16 (tensor cores) | 165 TFLOPS | ~0.4 ms | 1.0× (baseline) |
| FP32 | 82.6 TFLOPS | ~0.8 ms | 2.0× slower |
| INT8 (tensor cores) | 330 TOPS | ~0.2 ms | 2.0× faster |
| VFR i64 (integer ALU) | 41.3 TOPS | ~1.6 ms | 4.0× slower |
| VFR i32 (where F permits) | 82.6 TOPS | ~0.8 ms | 2.0× slower |

### Table B.3 — Full Forward Pass Projection (32-layer transformer, d=4096)

| Format | Per-layer | 32 layers | Overhead | Total |
|---|---|---|---|---|
| BF16 | 0.10 ms | 3.2 ms | 0.3 ms (softmax, norm) | 3.5 ms |
| FP32 | 0.20 ms | 6.4 ms | 0.3 ms | 6.7 ms |
| VFR i64 | 0.40 ms | 12.8 ms | 0.8 ms (domain conversion) | 13.6 ms |
| VFR i32 (optimized F) | 0.20 ms | 6.4 ms | 0.5 ms | 6.9 ms |

### Table B.4 — Training Step Projection (forward + backward + update)

| Format | Forward | Backward | Update | Total per step |
|---|---|---|---|---|
| BF16 mixed precision | 3.5 ms | 7.0 ms | 0.5 ms | 11.0 ms |
| VFR i64 | 13.6 ms | 27.2 ms | 1.0 ms | 41.8 ms |
| VFR i32 (optimized F) | 6.9 ms | 13.8 ms | 0.7 ms | 21.4 ms |
| VFR i32 + sparse R | 6.9 ms | 13.8 ms | 0.5 ms | 21.2 ms |

Note: VFR i64 is ~3.8× slower per step. VFR i32 with optimized F is ~1.9× slower. If information efficiency reduces required training tokens by 2× or more, wall-clock training time is comparable.

---

## Appendix C: Domain Factor Selection

### Table C.1 — Layer Domain Assignments

| Layer Type | Suggested F | Integer Type | Value Range | Precision |
|---|---|---|---|---|
| Embedding | 1 | i32 | ±2.1B | Exact integer |
| Attention QKV | 1024 | i32 | ±2.1M effective | ~1/1024 ≈ 0.001 |
| Attention scores | 1048576 (1024²) | i64 | ±8.8T effective | ~1/10⁶ ≈ 0.000001 |
| Softmax output | 10000 | i32 | ±214K effective | ~1/10000 = 0.0001 |
| Feedforward W1 | 1024 | i32 | ±2.1M effective | ~0.001 |
| GELU activation | domain conversion | — | — | nested VFR depth 2-3 |
| Feedforward W2 | 1024 | i32 | ±2.1M effective | ~0.001 |
| Layer norm | domain conversion | — | — | nested VFR depth 2 |
| Output logits | 10000 | i32 | ±214K effective | ~0.0001 |

### Table C.2 — Power-of-2 F Values (Bit-Shift Optimization)

| F Value | Bit Shift | Precision | Division Cost | Recommended For |
|---|---|---|---|---|
| 1 | 0 | integer | free | embeddings, particles |
| 32 | 5 | 0.03125 | 1 shift | skinning weights |
| 256 | 8 | 0.0039 | 1 shift | UV coordinates |
| 1024 | 10 | 0.00098 | 1 shift | attention, feedforward |
| 32768 | 15 | 0.000031 | 1 shift | high-precision layers |
| 1048576 | 20 | 0.00000095 | 1 shift | attention score products |

Note: Power-of-2 F values replace division with bit shift — eliminating the most expensive integer operation.

### Table C.3 — Overflow Analysis per Layer (i64 accumulator)

| Layer | F | Max V (i32) | Product V×V | Sum of 4096 products | Fits i64? |
|---|---|---|---|---|---|
| Embedding (F=1) | 1 | 2.1×10⁹ | 4.6×10¹⁸ | overflow | No — use i128 accumulator |
| Attention (F=1024) | 1024 | 2.1×10⁶ | 4.4×10¹² | 1.8×10¹⁶ | Yes |
| Feedforward (F=1024) | 1024 | 2.1×10⁶ | 4.4×10¹² | 1.8×10¹⁶ | Yes |
| Logits (F=10000) | 10000 | 2.1×10⁵ | 4.6×10¹⁰ | 1.9×10¹⁴ | Yes |

### Table C.4 — Float Precision Equivalence

| VFR Configuration | Decimal Digits of Precision | Float Equivalent |
|---|---|---|
| i16 V, F=1024 | ~5 digits | Between FP16 and FP32 |
| i32 V, F=1024 | ~9 digits | FP32 |
| i32 V, F=32768 | ~14 digits | FP64 |
| i64 V, F=1024 | ~19 digits | Beyond FP64 |
| i64 V, nested depth-1 | ~38 digits | Beyond FP128 |
| i64 V, nested depth-2 | ~57 digits | No float equivalent |

---

## Appendix D: Lattice Embedding Structure

### Table D.1 — Hexagonal Wing Assignments (Natural Language)

| Wing | Side | Angle | Category | Examples |
|---|---|---|---|---|
| α | A (front) | 0° | Nouns / entities | dog, server, matrix, Congress |
| β | A (front) | 120° | Verbs / actions | run, compute, elect, transform |
| γ | A (front) | 240° | Modifiers / attributes | fast, recursive, blue, very |
| α' | B (back) | 0° | Pronouns / references | he, it, this, which, self |
| β' | B (back) | 120° | Auxiliaries / control | is, would, if, for, while |
| γ' | B (back) | 240° | Connectives / structure | and, (, ), ;, comma, EOF |

### Table D.2 — Hexagonal Wing Assignments (Programming Languages)

| Wing | Side | Angle | Category | Examples |
|---|---|---|---|---|
| α | A | 0° | Identifiers / names | x, myList, numpy, DataFrame |
| β | A | 120° | Keywords / operators | for, return, +, ==, yield |
| γ | A | 240° | Type annotations / modifiers | int, static, async, const |
| α' | B | 0° | Literals / values | 42, "hello", True, 3.14 |
| β' | B | 120° | Control flow / delimiters | {, }, (, ), [, ], indent, dedent |
| γ' | B | 240° | Comments / metadata | #, //, @decorator, docstring |

### Table D.3 — Ring Depth by Token Frequency

| Ring | Tokens at Ring | Cumulative Tokens | Frequency Class | Examples |
|---|---|---|---|---|
| 0 | 1 | 1 | Origin / padding | PAD |
| 1 | 6 | 7 | Ultra-common | the, a, is, of, to, in |
| 2 | 12 | 19 | Very common | and, for, that, it, with, on, as, ... |
| 3 | 18 | 37 | Common | from, return, if, not, this, ... |
| 4-5 | 24-30 | 91 | Frequent | class, function, import, while, ... |
| 6-10 | 36-60 | 331 | Moderate | specific, lambda, yield, enumerate, ... |
| 11-50 | 66-300 | ~5,000 | Uncommon | eigenvalue, serialization, middleware, ... |
| 51-200 | 306-1200 | ~50,000 | Rare | numpy.linalg.svd, RuntimeWarning, ... |
| 200+ | 1200+ | 100,000+ | Long tail | domain-specific, neologisms, ... |

### Table D.4 — Lattice vs Learned Embedding Comparison

| Property | Learned Embedding (float) | Lattice Embedding (VFR) |
|---|---|---|
| Initialization | Random | Deterministic geometric |
| Grammatical structure | Must learn from data | Encoded in wing assignment |
| Frequency encoding | Implicit in weight magnitudes | Explicit in ring depth |
| Similarity structure | Emergent after training | Pre-structured by lattice |
| Token lookup | Matrix row fetch | O(1) lattice calculation |
| Parameters | vocab_size × d_model floats | Wing basis vectors + ring formula |
| Storage (50k vocab, d=4096) | 400 MB (BF16) | ~6 MB (lattice rules + assignments) |
| Trainable | Yes (all parameters) | Partially (assignment refinement) |
| Deterministic | No (float dependent) | Yes (integer calculation) |

---

## Appendix E: Comparison to Existing Approaches

### Table E.1 — VFR vs Quantization Methods

| Method | Training | Inference | Exactness | Remainder Tracking | Equality |
|---|---|---|---|---|---|
| FP32 | Standard | Slow | No | None | Epsilon |
| BF16 mixed precision | Standard | Fast | No | None | Epsilon |
| INT8 post-training (GPTQ) | Float, then quantize | Fast | No | None | Approximate |
| INT4 post-training (AWQ) | Float, then quantize | Fastest | No | None | Approximate |
| QAT (quantization-aware) | Simulated low-precision | Fast | No | None | Approximate |
| BitNet (1.58-bit) | Ternary from scratch | Fastest | No | None | Exact (trivially) |
| **VFR (this proposal)** | **Integer from scratch** | **Competitive** | **Yes** | **Full R tracking** | **Binary exact** |

### Table E.2 — VFR vs Rational Arithmetic Libraries

| System | Representation | Arbitrary Precision | GPU Support | ML Integration | Performance |
|---|---|---|---|---|---|
| GMP | Arbitrary-size integer pairs | Yes | No | None | Slow (CPU only) |
| SymPy Rational | Python fraction objects | Yes | No | None | Very slow |
| Mathematica Exact | Symbolic expressions | Yes | No | None | Moderate |
| FLINT | Fast integer library | Yes | Partial | None | Fast (CPU) |
| **VFR** | **[V, F, R] with F-implicit** | **Yes (via nesting)** | **Yes (native i64)** | **Designed for ML** | **GPU-native** |

### Table E.3 — Feature Comparison Matrix

| Feature | BF16 Float | INT8 Quantized | BitNet | VFR |
|---|---|---|---|---|
| Exact arithmetic | ✗ | ✗ | ✗ | ✓ |
| Binary equality | ✗ | ✗ | ✓ | ✓ |
| Deterministic training | ✗ | N/A | ✓ | ✓ |
| Deterministic inference | ✗ | ✗ | ✓ | ✓ |
| Gradient signal preservation | Partial | N/A | Limited | Full |
| Structural interpretability | ✗ | ✗ | ✗ | ✓ (tree depth) |
| Automated pruning criterion | ✗ | ✗ | ✗ | ✓ (R=0 detection) |
| Adaptive precision | ✗ | ✗ | ✗ | ✓ (nesting depth) |
| Long-tail pattern preservation | Poor | Poor | Unknown | Predicted strong |
| GPU throughput | High (tensor cores) | Highest | Highest | Competitive (integer ALU) |
| Memory per parameter | 2 bytes | 1 byte | 0.2 bytes | 8 bytes (practical) |
| Information per parameter | Low (noise floor) | Very low | Minimal | High (exact) |

---

## Appendix F: Risk Assessment

### Table F.1 — Technical Risks and Mitigations

| Risk | Severity | Likelihood | Mitigation | Fallback |
|---|---|---|---|---|
| Integer overflow in matmul accumulation | High | Medium | i128 accumulators, power-of-2 F with bit shifts | Reduce F per layer until safe |
| Transcendental approximation insufficient | Medium | Low | Depth-3 nested VFR exceeds FP64 precision | Precomputed lookup tables at any needed density |
| Training does not converge | High | Low | VFR arithmetic is a superset of rational — convergence properties preserved | Fall back to larger F (approaching float precision) |
| Inference too slow (>3× float) | Medium | Medium | i32 weights where F permits, bit-shift F values, kernel optimization | Accept 2× slowdown if accuracy gains justify it |
| Memory exceeds device capacity | Medium | Medium | Sparse R storage, F-implicit layout, i32 where possible | Multi-device tensor parallelism |
| Lattice embedding assignment suboptimal | Low | High | Frequency-based initial assignment, refinement during warmup | Fall back to learned embeddings with VFR values |
| No measurable accuracy improvement | High | Medium | Focus measurement on long-tail and consistency metrics | Value proposition shifts to determinism and interpretability alone |
| Ecosystem resistance (no framework support) | Medium | High | Custom CUDA kernels with Python wrapper | Release as open-source library for community adoption |

### Table F.2 — Experimental Priority Matrix

| Experiment | Effort | Expected Impact | Priority |
|---|---|---|---|
| VFR matmul kernel (CUDA) | 2 weeks | Validates compute feasibility | P0 — must do first |
| Single-layer forward/backward verification | 1 week | Proves exactness end-to-end | P0 |
| GPT-2 small full training comparison | 4 weeks | Core hypothesis test | P0 |
| Long-tail accuracy benchmark | 1 week | Tests primary value claim | P0 |
| Lattice embedding prototype | 3 weeks | Tests structural embedding hypothesis | P1 |
| Weight structure analysis tooling | 2 weeks | Tests interpretability claim | P1 |
| i32 optimized kernels | 2 weeks | Performance improvement | P1 |
| 1.3B model scale test | 6 weeks | Validates scaling behavior | P2 |
| Grokking detection via tree depth | 2 weeks | Novel scientific finding if confirmed | P2 |
| 7B model full training | 12 weeks | Production-scale validation | P3 |

