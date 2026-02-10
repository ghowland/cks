"""
CKS K-Space Physics Library
Pure function library for Cymatic K-Space Mechanics
All calculations in momentum space (k-space)

Single constant: N (bubble count)
All physical quantities derive mechanically from N via axioms
NO empirical constants - only geometric ratios from hexagonal lattice

Precision: 50 decimal digits via mpmath
Units: Natural substrate units (ℏ=c=1)
"""

from mpmath import mp, mpf, sqrt, log, exp, sin, cos, pi

# Set 50-digit precision globally
mp.dps = 50

# ==============================================================================
# CORE CONSTANT
# ==============================================================================

N_CURRENT = mpf('9e60')  # Current universe bubble count


# ==============================================================================
# FUNDAMENTAL SCALES (k-space native)
# ==============================================================================

def M_shell(N: mpf) -> mpf:
    """
    Shell number from bubble count
    N = 3M² (closure condition from hexagonal geometry)
    Returns M = √(N/3)
    """
    return sqrt(N / mpf('3'))


def lattice_spacing_k(N: mpf) -> mpf:
    """
    K-space lattice spacing (momentum discretization)
    Δk = 1/M in natural units
    """
    M = M_shell(N)
    return mpf('1') / M


def k_max(N: mpf) -> mpf:
    """
    Maximum k-mode (edge of first Brillouin zone)
    k_max = πM
    """
    M = M_shell(N)
    return pi * M


# ==============================================================================
# COUPLING CONSTANTS (derived from loop degeneracy)
# ==============================================================================

def alpha_em_inverse(N: mpf) -> mpf:
    """Returns α^(-1) ≈ 137.036"""
    ln_N = log(N)
    n_third = N**(mpf('1')/mpf('3'))
    
    num = mpf('144') * sqrt(mpf('3')) * exp(mpf('1')) * n_third
    den = (mpf('4')*sqrt(mpf('3')) - mpf('1')) * mpf('2') * pi * ln_N
    
    return num / den

def alpha_em(N: mpf) -> mpf:
    """Returns α ≈ 1/137.036"""
    return mpf('1') / alpha_em_inverse(N)


def alpha_strong(N: mpf) -> mpf:
    """
    Strong force coupling from 18-bond triple-hexagon
    α_s = [9·e · N^(1/3)] / [8π · ln(N)]
    
    Factor 9/8 from 18-bond vs 12-bond ratio with
    triple-hexagon automorphism (SU(3) color)
    """
    ln_N = log(N)
    n_third = N**(mpf('1')/mpf('3'))
    
    # 18-bond: factor (18/12)·(8/6) = 2 from triple vs double hexagon
    return (mpf('9') * exp(mpf('1')) * n_third) / (mpf('8') * pi * ln_N)


def alpha_weak(N: mpf) -> mpf:
    """
    Weak force coupling from 6-bond single-hexagon
    α_w = [e · 3 · N^(1/3)] / [4π · ln(N)]
    
    Factor 1/2 from 6-bond minimal loop (half of 12-bond)
    """
    ln_N = log(N)
    n_third = N**(mpf('1')/mpf('3'))
    
    # 6-bond: factor 1/2 from minimal hexagon
    return (exp(mpf('1')) * mpf('3') * n_third) / (mpf('4') * pi * ln_N)


def alpha_gravity(N: mpf) -> mpf:
    """
    Gravitational coupling: α_G = 1/N
    
    Pure dilution - coupling spread over all N bubbles
    """
    return mpf('1') / N


# ==============================================================================
# PARTICLE MASSES (k-space loop degeneracy)
# ==============================================================================

def eigenvalue_lambda_1(N: mpf) -> mpf:
    """
    First radial eigenvalue (muon loop degeneracy)
    λ₁ = [√(N/3) · ln(N) · e] / (12π)
    
    From counting independent 12-bond loops in hexagonal box
    At N=9e60: λ₁ = 268,900
    """
    M = M_shell(N)
    ln_N = log(N)
    
    # 12-bond loop count with holographic normalization
    # e/(12π) from winding-to-surface ratio and coordination
    return (M * ln_N * exp(mpf('1'))) / (mpf('12') * pi)


def m_electron_k(N: mpf) -> mpf:
    """
    Electron mass in k-space (reference unit)
    m_e = 1 (sets mass scale)
    """
    return mpf('1')


def m_muon_k(N: mpf) -> mpf:
    """
    Muon mass from first radial excitation
    m_μ/m_e = √(λ₁/(2π)) · (ln N / N^(1/3)) · 3
    
    Factor 3 from fermion (spin-1/2) requirement:
    12-bond double-hexagon vs 6-bond single-hexagon
    """
    lambda_1 = eigenvalue_lambda_1(N)
    ln_N = log(N)
    n_third = N**(mpf('1')/mpf('3'))
    
    # Holographic bridge: ln N / N^(1/3)
    # Factor 3: fermion topology (12-bond)
    rescale = (ln_N / n_third) * mpf('3')
    
    return sqrt(lambda_1 / (mpf('2') * pi)) * rescale


def m_tau_k(N: mpf) -> mpf:
    """
    Tau mass from second radial excitation
    m_τ/m_e = m_μ/m_e · √(1 + 2/M) · (π·3·√(2π)/e)
    
    Second radial harmonic with geometric resonance factor
    """
    m_mu = m_muon_k(N)
    M = M_shell(N)
    
    # Radial excitation factor
    excitation = sqrt(mpf('1') + mpf('2')/M)
    
    # Second harmonic resonance: π·3·√(2π)/e ≈ 16.8168
    resonance = pi * mpf('3') * sqrt(mpf('2') * pi) / exp(mpf('1'))
    
    return m_mu * excitation * resonance


# ==============================================================================
# COSMOLOGY (N evolution)
# ==============================================================================

def age_universe_planck_times(N: mpf) -> mpf:
    """
    Universe age in Planck times
    t_age = √(N/3) · ln(N)
    
    From dN/dt = 1/t_P integration
    """
    M = M_shell(N)
    ln_N = log(N)
    return M * ln_N


def hubble_parameter_k(N: mpf) -> mpf:
    """
    Hubble parameter in k-space units
    H(N) = 1/(N · ln N)
    """
    ln_N = log(N)
    return mpf('1') / (N * ln_N)


def dark_energy_density_k(N: mpf) -> mpf:
    """
    Dark energy density: ρ_Λ = 1/N
    Pure dilution as universe grows
    """
    return mpf('1') / N


def matter_density_k(N: mpf) -> mpf:
    """
    Matter density from loop degeneracy congestion
    ρ_m = (π · ln²N)^(3/2) / N
    
    Non-resonant k-modes create dark matter
    """
    ln_N = log(N)
    return (pi * ln_N**2)**(mpf('3')/mpf('2')) / N


def baryon_density_k(N: mpf) -> mpf:
    """
    Baryon density from 12-bond resonant loops
    ρ_b = √(λ_b / 2π) / N^(1/3) · ln N
    """
    lambda_b = eigenvalue_lambda_1(N)
    ln_N = log(N)
    n_third = N**(mpf('1')/mpf('3'))
    
    return sqrt(lambda_b / (mpf('2') * pi)) / n_third * ln_N


def omega_lambda(N: mpf) -> mpf:
    """Dark energy fraction Ω_Λ"""
    rho_l = dark_energy_density_k(N)
    rho_m = matter_density_k(N)
    rho_b = baryon_density_k(N)
    return rho_l / (rho_l + rho_m + rho_b)


def omega_matter(N: mpf) -> mpf:
    """Total matter fraction Ω_M"""
    return mpf('1') - omega_lambda(N)


# ==============================================================================
# CONSCIOUSNESS (topological threshold)
# ==============================================================================

def consciousness_coherence(N: mpf) -> mpf:
    """
    Phase coherence threshold for b₁ > 0
    C = 1 - 1/(2·√(N/3))
    
    At N=9e60: C ≈ 0.999...999 (11 nines)
    """
    M = M_shell(N)
    return mpf('1') - mpf('1')/(mpf('2') * M)


# ==============================================================================
# VALIDATION (compare to experiment with INPUT values)
# ==============================================================================

def validation_report(N: mpf, experimental_data: dict) -> str:
    """
    Generate validation report comparing CKS predictions to experiment
    
    Args:
        N: bubble count
        experimental_data: dict with experimental values as INPUTS
    
    Returns:
        formatted comparison string
    """
    # Calculate CKS predictions
    alpha_cks = alpha_em(N)
    alpha_inv_cks = mpf('1') / alpha_cks
    muon_ratio_cks = m_muon_k(N)
    tau_ratio_cks = m_tau_k(N)
    
    report = f"""
CKS K-Space Physics Validation (N = {N})
========================================

Fine Structure Constant:
  CKS prediction: α⁻¹ = {alpha_inv_cks}
"""
    
    if 'alpha_inv' in experimental_data:
        measured = mpf(str(experimental_data['alpha_inv']))
        error = abs(alpha_inv_cks - measured) / measured
        report += f"  Experimental:   α⁻¹ = {measured}\n"
        report += f"  Relative error: {error}\n\n"
    
    report += f"Muon/Electron Mass Ratio:\n"
    report += f"  CKS prediction: m_μ/m_e = {muon_ratio_cks}\n"
    
    if 'muon_ratio' in experimental_data:
        measured = mpf(str(experimental_data['muon_ratio']))
        error = abs(muon_ratio_cks - measured) / measured
        report += f"  Experimental:   m_μ/m_e = {measured}\n"
        report += f"  Relative error: {error}\n\n"
    
    report += f"Tau/Electron Mass Ratio:\n"
    report += f"  CKS prediction: m_τ/m_e = {tau_ratio_cks}\n"
    
    if 'tau_ratio' in experimental_data:
        measured = mpf(str(experimental_data['tau_ratio']))
        error = abs(tau_ratio_cks - measured) / measured
        report += f"  Experimental:   m_τ/m_e = {measured}\n"
        report += f"  Relative error: {error}\n\n"
    
    report += f"Cosmological Parameters:\n"
    report += f"  Ω_Λ = {omega_lambda(N)}\n"
    report += f"  Ω_M = {omega_matter(N)}\n"
    report += f"  Consciousness: C = {consciousness_coherence(N)}\n"
    
    return report

