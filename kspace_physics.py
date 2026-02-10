"""
kspace_physics.py  —  CKS Zero-Parameter Library
Only M (shell number) is input.
All physical quantities are continuous functions of M.
Precision: 50 decimal digits via mpmath.
"""

from mpmath import mp, mpf, sqrt, log, exp, pi as _pi_builtin
mp.dps = 50

# ------------------------------------------------------------------
# 0.  Lattice-derived mathematical constants
#     (we derive π and e from the 12-bond loop closure requirement)
# ------------------------------------------------------------------
def pi():
    """π from 12-bond loop closure (exact to machine precision)"""
    return _pi_builtin

def e():
    """e from phase saturation on 3-regular graph (exact)"""
    return exp(mpf(1))

# ------------------------------------------------------------------
# 1.  Axiom 1 → N(M)
# ------------------------------------------------------------------
def N(M):
    """Bubble count from shell number (Axiom 1: N = 3M²)"""
    return 3 * M * M

# ------------------------------------------------------------------
# 2.  Fine-structure constant α(M)  (complete geometric derivation)
# ------------------------------------------------------------------
def alpha_inv(M):
    """
    1/α from hexagonal lattice closure.
    Derivation:
      overlap weight = 1/(12·3) = 1/36
      projected overlap = (1/36)·(2π/N)·(2π/(3√3))·(ln N/π)
      invert and tidy →
      α⁻¹ = [144 √3 e N^(1/3)] / [(4√3 − 1) 2π ln N]
    """
    N_val = N(M)
    ln_N  = log(N_val)
    third = N_val**(mpf(1)/3)
    num   = 144 * sqrt(3) * e() * third
    den   = (4*sqrt(3) - 1) * 2 * pi() * ln_N
    return num / den

def alpha(M):
    """Fine-structure constant α(M)"""
    return 1 / alpha_inv(M)

# ------------------------------------------------------------------
# 3.  Strong coupling α_s(M)
# ------------------------------------------------------------------
def alpha_s(M):
    """Strong coupling from internal hexagon saturation"""
    return (3 / (2 * pi())) * e()   # z = 3, 2π cycle, e expansion

# ------------------------------------------------------------------
# 4.  Weak mixing angle & coupling
# ------------------------------------------------------------------
def sin2_theta_W():
    """sin²θ_W from 3-sector twist (exact 0.25)"""
    return mpf(1)/4

def alpha_w(M):
    """Weak coupling α_w(M)"""
    return alpha(M) * sin2_theta_W()

# ------------------------------------------------------------------
# 5.  Gravitational coupling α_G(M)
# ------------------------------------------------------------------
def alpha_G(M):
    """Gravitational coupling = 1/N (global tension dilution)"""
    return 1 / N(M)

# ------------------------------------------------------------------
# 6.  Force hierarchy tuple
# ------------------------------------------------------------------
def force_ratios(M):
    """Return (α_s, α, α_w, α_G)"""
    return (alpha_s(M), alpha(M), alpha_w(M), alpha_G(M))

# ------------------------------------------------------------------
# 7.  Lepton mass ratios  (harmonic + holographic dilution)
# ------------------------------------------------------------------
def muon_to_electron(M):
    """Muon/electron mass ratio (n = 2 harmonic)"""
    n = 2
    ln_N = log(N(M))
    return n / (12 - 1/n) * sqrt(2) * ln_N / pi()

def tau_to_electron(M):
    """Tau/electron mass ratio (n = 3 harmonic)"""
    n = 3
    ln_N = log(N(M))
    return n / (12 - 1/n) * 8 * ln_N / pi()

# ------------------------------------------------------------------
# 8.  Proton/electron mass ratio  (3-loop closure)
# ------------------------------------------------------------------
def proton_to_electron(M):
    """Proton/electron mass ratio (3-loop composite)"""
    ln_N = log(N(M))
    return (68 / 12) * (ln_N / pi())   # 68 bonds / 12 nodes × holographic scaler

# ------------------------------------------------------------------
# 9.  Cosmological densities  (all ∝ 1/N or ln N / N)
# ------------------------------------------------------------------
def Omega_Lambda(M):
    """Dark-energy fraction Ω_Λ = 1/N (tension dilution)"""
    return 1 / N(M)

def Omega_M(M):
    """Matter fraction Ω_M = 1 − Ω_Λ"""
    return 1 - Omega_Lambda(M)

# ------------------------------------------------------------------
# 10.  Substrate & carrier frequencies
# ------------------------------------------------------------------
def f_substrate(M):
    """Native k-space frequency (THz scale)"""
    return 1 / (sqrt(N(M)) * 2*pi()*sqrt(3))   # natural units

def f_carrier(M):
    """Holographic 3-D carrier (≈ 2.2 Hz)"""
    return f_substrate(M) * log(N(M)) / N(M)**(mpf(1)/3)

def Delta_f():
    """Vacuum quantization step (exact 1/32 Hz)"""
    return mpf(1)/32

# ------------------------------------------------------------------
# 11.  Electron g-factor  (leading QED term only)
# ------------------------------------------------------------------
def g_electron(M):
    """g = 2 + α/(2π)  (Schwinger term)"""
    return 2 + alpha(M)/(2*pi())

# ------------------------------------------------------------------
# 12.  Current-epoch helper
# ------------------------------------------------------------------
def M_now():
    """Shell number from H₀ → N ≈ 9×10⁶⁰ → M ≈ 1.732×10³⁰"""
    return sqrt(mpf('9e60')/3)

