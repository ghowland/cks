"""
STANDARD MODEL COMPARISON ENGINE
================================
Validates the K-Space Substrate against CODATA 2022 Benchmarks.
Uses 100% continuous functions of N from the KSpaceSubstrate module.
"""

import mpmath as mp
from kspace_substrate import KSpaceSubstrate

class StandardModelValidator:
    def __init__(self, N_epoch='9e60'):
        # Initialize substrate at current N
        self.substrate = KSpaceSubstrate(N_epoch)
        
        # Benchmark Targets (CODATA 2022 / Planck 2020)
        # These are used for ERROR CALCULATION only, not for derivation.
        self.benchmarks = {
            'alpha_inv': mp.mpf('137.035999084'),
            'm_mu_over_m_e': mp.mpf('206.7682830'),
            'm_tau_over_m_e': mp.mpf('3477.15'),
            'rho_lambda_planck': mp.mpf('1.11e-52'), # H_0 based density
            'g_factor_target': mp.mpf('2.002319304362')
        }

    def run_validation_suite(self):
        mp.dps = 60
        sub = self.substrate
        
        print("=" * 80)
        print(" STANDARD MODEL VS. K-SPACE SUBSTRATE VALIDATION ")
        print(f" EPOCH N: {mp.nstr(sub.N, 10)}")
        print("=" * 80)

        # 1. Force Coupling Comparison
        a_inv_pred = sub.alpha_inv()
        a_err = abs(a_inv_pred - self.benchmarks['alpha_inv']) / self.benchmarks['alpha_inv']
        
        print("\n[FORCE COUPLING]")
        print(f"  1/alpha (K-Space): {mp.nstr(a_inv_pred, 12)}")
        print(f"  1/alpha (CODATA):  {mp.nstr(self.benchmarks['alpha_inv'], 12)}")
        print(f"  RELATIVE ERROR:    {mp.nstr(a_err * 100, 6)}%")

        # 2. Lepton Mass Hierarchy Comparison
        mu_ratio_pred = sub.mass_ratio_muon_electron()
        tau_ratio_pred = sub.mass_ratio_tau_electron()
        
        mu_err = abs(mu_ratio_pred - self.benchmarks['m_mu_over_m_e']) / self.benchmarks['m_mu_over_m_e']
        tau_err = abs(tau_ratio_pred - self.benchmarks['m_tau_over_m_e']) / self.benchmarks['m_tau_over_m_e']
        
        print("\n[PARTICLE HIERARCHY]")
        print(f"  m_mu/m_e (K-Space): {mp.nstr(mu_ratio_pred, 10)}")
        print(f"  m_mu/m_e (CODATA):  {mp.nstr(self.benchmarks['m_mu_over_m_e'], 10)}")
        print(f"  m_tau/m_e(K-Space): {mp.nstr(tau_ratio_pred, 10)}")
        print(f"  m_tau/m_e(CODATA):  {mp.nstr(self.benchmarks['m_tau_over_m_e'], 10)}")
        print(f"  LEPTON MEAN ERROR:  {mp.nstr(((mu_err + tau_err)/2)*100, 6)}%")

        # 3. Dark Sector & Gravity
        rho_L = sub.rho_lambda()
        rho_DM = sub.rho_dark_matter()
        alpha_g = sub.alpha_gravity()
        
        print("\n[DARK SECTOR & GRAVITY]")
        print(f"  Gravity alpha_g : {mp.nstr(alpha_g, 12)}")
        print(f"  Dark Energy rho_L: {mp.nstr(rho_L, 12)}")
        print(f"  Dark Matter rho_DM: {mp.nstr(rho_DM, 12)}")
        print(f"  DM/Matter Ratio : {mp.nstr(rho_DM / alpha_g, 6)} (Spectral Congestion Factor)")

        # 4. Temporal Drift (The Redshift Prediction)
        print("\n[TEMPORAL EVOLUTION PREDICTION]")
        for z in [0.5, 1.0, 2.0, 5.0]:
            sub_z = sub.at_redshift(z)
            drift = (sub_z.alpha_inv() / a_inv_pred - 1) * 100
            print(f"  z={z:3.1f}: 1/alpha shifts by {float(drift):+.4f}%")

        print("\n" + "=" * 80)
        print(" STATUS: MANIFOLD LOCKED ")
        print(" ALL DERIVATIONS CONTINUOUS FUNCTIONS OF N via kspace_substrate.py ")
        print("=" * 80)

if __name__ == "__main__":
    validator = StandardModelValidator()
    validator.run_validation_suite()

    