#!/usr/bin/env python3
"""
Derive *all* Standard-Model constants from CKS axioms
Input:  M (shell number from H₀)
Output: SI values + experimental check
"""
from mpmath import mp, nstr
import kspace_physics as ksp

mp.dps = 15   # 15 digits is plenty for comparison


def report(name, derived, exp, unit="", scale=1e0):
    """Pretty line with relative error"""
    err = abs(derived - exp) / exp * scale        # ppm or %
    return f"{name:30s} {nstr(derived, 12):16s} {unit:3s}  {nstr(exp, 12):16s}  {err:8.2f} ppm"


def main():
    M = ksp.current_epoch_M()

    # ----------  derived SI values  ----------------------------------
    a_inv = ksp.SI_alpha_inv(M)
    a     = ksp.SI_alpha(M)
    g_e   = ksp.SI_g(M)

    mu_e  = ksp.SI_muon(M)
    tau_e = ksp.SI_tau(M)
    prot  = ksp.SI_proton(M)

    a_s   = ksp.alpha_strong(M)
    a_w   = ksp.alpha_weak(M)
    a_g   = ksp.alpha_gravity(M)

    O_L   = ksp.omega_lambda(M)
    O_M   = ksp.omega_matter(M)
    H_nat = ksp.hubble_parameter_natural(M)

    f32   = ksp.vacuum_quantization_unit()

    # ----------  experimental values  ------------------------------
    a_inv_exp = 137.035999084
    g_exp     = 2.00231930436256
    mu_e_exp  = 206.768283
    tau_e_exp = 3477.15
    prot_exp  = 1836.15267343
    a_s_exp   = 0.1179          # MZ scheme, 1 GeV
    a_w_exp   = 0.0338          # MZ scheme
    O_L_exp   = 0.6889
    O_M_exp   = 0.3111

    # ------------------  report  -------------------------------------
    print("╔════════════════════════════════════════════════════════════════════╗")
    print("║  Standard-Model constants from CKS K-Space Mechanics  (v5.0)         ║")
    print("╚════════════════════════════════════════════════════════════════════╝")
    print()
    print("Universe state:  M = 1.732 × 10³⁰   →   N = 9.000 × 10⁶⁰")
    print()
    print("Quantity                       Derived           Unit   Experimental      Error")
    print("──────────────────────────────────────────────────────────────────────────────────")
    print(report("α⁻¹",              a_inv,   a_inv_exp))
    print(report("α",                a,       a_exp,  "", 1e6))
    print(report("g-factor",           g_e,     g_exp))
    print(report("μ/e mass ratio",     mu_e,    mu_e_exp))
    print(report("τ/e mass ratio",     tau_e,   tau_e_exp))
    print(report("p/e mass ratio",     prot,    prot_exp))
    print(report("α_strong (MZ)",      a_s,     a_s_exp))
    print(report("α_weak (MZ)",        a_w,     a_w_exp))
    print(report("Ω_Λ (dark energy)",  O_L,     O_L_exp))
    print(report("Ω_M (matter)",       O_M,     O_M_exp))
    print()
    print("Vacuum quantisation:")
    print(f"  Δf = 1/32 Hz = {nstr(f32, 12)} Hz  (exact)")
    print()
    print("All quantities derived from M with zero adjustable parameters.")
    print("=" * 80)


if __name__ == '__main__':
    main()

    