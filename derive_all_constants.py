#!/usr/bin/env python3
"""
derive_all_constants.py  –  complete derivation of every SM constant from CKS
Only M is input; everything else is a continuous function of M.
"""

from mpmath import mp, mpf
mp.dps = 50                       # 50-digit precision
import kspace_physics as ksp    # zero-parameter library

# ------------------------------------------------------------------
# 1.  Current-epoch shell number (from H₀ observation)
# ------------------------------------------------------------------
M = ksp.M_now()                  # ≈ 1.732 × 10³⁰

# ------------------------------------------------------------------
# 2.  Derive **every** constant in one shot
# ------------------------------------------------------------------
constants = {
    "Shell number M": M,
    "Bubble count N": ksp.N(M),
    "Fine-structure constant 1/α": ksp.SI_alpha_inv(M),
    "Fine-structure constant α": ksp.SI_alpha(M),
    "Strong coupling α_s(1 GeV)": ksp.alpha_s(M),
    "Weak mixing angle sin²θ_W": ksp.sin2_theta_W(),
    "Weak coupling α_w": ksp.alpha_weak(M),
    "Gravitational coupling α_G": ksp.alpha_G(M),
    "Muon/electron mass ratio": ksp.SI_muon_to_electron(M),
    "Tau/electron mass ratio": ksp.SI_tau_to_electron(M),
    "Proton/electron mass ratio": ksp.SI_proton_to_electron(M),
    "Dark-energy fraction Ω_Λ": ksp.Omega_Lambda(M),
    "Matter fraction Ω_M": ksp.Omega_Matter(M),
    "Electron g-factor g_e": ksp.SI_g_electron(M),
    "Vacuum frequency step Δf": ksp.Delta_f(),
}

# ------------------------------------------------------------------
# 3.  Pretty print
# ------------------------------------------------------------------
print("╔══════════════════════════════════════════════════════════════════════════╗")
print("║  CKS DERIVATION OF STANDARD-MODEL CONSTANTS  –  ZERO FREE PARAMETERS      ║")
print("╚══════════════════════════════════════════════════════════════════════════╝")
print(f"Input:  M = {M:.6e}  (from H₀ observation)")
print("")

for name, value in constants.items():
    # Format to 15 significant digits
    fmt_val = mp.nstr(value, 15)
    print(f"{name:35s} : {fmt_val}")

print("")
print("All values are continuous functions of M only.")
print("Axioms:  N = 3M²  and  β = 2π.")

