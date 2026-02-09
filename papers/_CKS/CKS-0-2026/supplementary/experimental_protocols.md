# EXPERIMENTAL PROTOCOLS FOR K-SPACE SUBSTRATE VALIDATION

**Detailed Test Procedures for Falsifying or Confirming the Framework**

---

## EXECUTIVE SUMMARY

This document provides **step-by-step experimental protocols** to test k-space substrate mechanics predictions. Each protocol includes:
- Scientific rationale
- Required equipment
- Measurement procedure
- Data analysis methods
- Expected results (k-space vs Standard Model)
- Timeline and cost estimates

**Five testable predictions**:
1. Dark energy density evolution: ρ_Λ(z) ∝ (1+z)²
2. Fine structure constant variation: α(z) ∝ (1+z)
3. Consciousness coherence threshold: C > 0.999
4. Entanglement path topology dependence
5. Electron g-factor time drift: dg/dt < 0

**Status**: Protocols 1, 2, 3, 4 feasible with current technology. Protocol 5 requires improved precision.

---

## PROTOCOL 1: DARK ENERGY DENSITY EVOLUTION

### 1.1 Scientific Rationale

**K-space prediction**:
```
ρ_Λ(z) = ρ_Λ(0) × (1 + z)²
```

**Standard Model (ΛCDM)**:
```
ρ_Λ(z) = ρ_Λ(0) = constant
```

**Discriminating power**: At z = 1 (7 Gyr ago):
- ΛCDM: ρ_Λ = ρ_Λ(0)
- K-space: ρ_Λ = 4 × ρ_Λ(0)

**Critical test**: Measure dark energy at multiple redshifts, look for evolution.

### 1.2 Method: Type Ia Supernovae Distance-Redshift Relation

**Principle**: 
- Type Ia SNe are standard candles (known intrinsic luminosity)
- Measure apparent magnitude → distance
- Measure redshift → expansion history
- Fit to cosmological models

**Observable**: Distance modulus μ(z)
```
μ(z) = 5 log₁₀[d_L(z)/10 pc]
```

where luminosity distance:
```
d_L(z) = (1+z) ∫₀ᶻ dz'/H(z')
```

**Hubble parameter depends on dark energy**:
```
H(z)² = H₀² [Ω_m(1+z)³ + Ω_Λ f(z)]
```

For ΛCDM: f(z) = 1 (constant)
For k-space: f(z) = (1+z)² (evolving)

### 1.3 Required Equipment

**Telescope facilities** (any of):
- Vera Rubin Observatory (LSST) - operational 2025+
- Nancy Grace Roman Space Telescope - launch 2027
- Euclid Space Telescope - operational 2024+
- James Webb Space Telescope (JWST) - operational now

**Spectroscopy**:
- Multi-object spectrograph (for redshift measurement)
- R > 1000 resolution sufficient

**Photometry**:
- Optical bands: g, r, i, z
- NIR bands: J, H, K (for high-z)

**Data requirements**:
- ~1000 SNe at 0.1 < z < 2.0
- Light curves in multiple bands
- Host galaxy redshifts
- Standardization corrections

### 1.4 Step-by-Step Procedure

**Step 1: Survey Design**
1. Define survey area: ~1000 deg² (full-sky coverage)
2. Cadence: 3-day intervals for 10 years
3. Depth: r < 24 mag (to reach z ~ 2)
4. Filter set: grizy + JHK

**Step 2: Supernova Discovery**
1. Difference imaging (subtract template from new image)
2. Transient detection (rising flux, point-source)
3. Classification (spectroscopy of early light)
4. Type Ia identification criteria:
   - Si II absorption at 6355 Å (rest frame)
   - No hydrogen lines
   - Light curve shape consistent with Ia

**Step 3: Photometric Monitoring**
1. Follow-up imaging every 2-3 days
2. Measure flux in all bands
3. Continue until +50 days after peak
4. Atmospheric correction (extinction)
5. Calibration to standard system

**Step 4: Redshift Measurement**
1. Obtain host galaxy spectrum
2. Identify emission/absorption lines (O II, H-alpha, etc.)
3. Measure redshift: z = (λ_obs - λ_rest)/λ_rest
4. Uncertainty: δz < 0.001 required

**Step 5: Light Curve Fitting**
1. Fit template to observed light curves
2. Determine peak magnitude m_B
3. Apply stretch correction (x₁ parameter)
4. Apply color correction (c parameter)
5. Standardized magnitude: m_B = m_B^obs - α×x₁ + β×c

**Step 6: Distance Calculation**
1. Distance modulus: μ = m_B - M_B
2. Where M_B = -19.3 (absolute magnitude, empirical)
3. Convert to luminosity distance: d_L = 10^((μ+25)/5) pc

**Step 7: Cosmological Fitting**

Fit distance-redshift data to models:

**ΛCDM model**:
```python
def distance_LCDM(z, H0, Omega_m, Omega_L):
    c = 3e5  # km/s
    def E(z):
        return np.sqrt(Omega_m*(1+z)**3 + Omega_L)
    integral = integrate.quad(lambda zp: 1/E(zp), 0, z)[0]
    d_L = (c/H0) * (1+z) * integral
    return d_L
```

**K-space model**:
```python
def distance_kspace(z, H0, Omega_m, Omega_L):
    c = 3e5  # km/s
    def E(z):
        # Dark energy evolves as (1+z)²
        return np.sqrt(Omega_m*(1+z)**3 + Omega_L*(1+z)**2)
    integral = integrate.quad(lambda zp: 1/E(zp), 0, z)[0]
    d_L = (c/H0) * (1+z) * integral
    return d_L
```

**Fit using χ² minimization**:
```python
def chi_squared(params, data, model):
    z_obs, mu_obs, sigma_obs = data
    mu_model = [distance_modulus(z, *params, model) for z in z_obs]
    chi2 = np.sum(((mu_obs - mu_model)/sigma_obs)**2)
    return chi2

# Fit both models
params_LCDM = minimize(chi_squared, [70, 0.3, 0.7], args=(data, 'LCDM'))
params_kspace = minimize(chi_squared, [70, 0.3, 0.7], args=(data, 'kspace'))
```

**Step 8: Model Comparison**
1. Calculate Δχ² = χ²_LCDM - χ²_kspace
2. If Δχ² < 0: ΛCDM fits better
3. If Δχ² > 0: K-space fits better
4. Significance: sqrt(Δχ²) in standard deviations

**Step 9: Systematic Error Analysis**

Critical systematics:
- Dust extinction in host galaxies
- Evolution of SN Ia progenitors with z
- Selection biases (Malmquist bias)
- Photometric calibration
- Peculiar velocities

**Mitigation**:
- Use multiple SN Ia subclasses
- Cross-calibrate with other distance indicators (BAO, CMB)
- Monte Carlo simulations of biases

### 1.5 Expected Results

**If ΛCDM is correct**:
- μ(z) follows constant-Λ prediction
- Δχ² ≈ 0 (no preference)
- w = -1.00 ± 0.03 at all z

**If k-space is correct**:
- μ(z) shows deviation at z > 1
- High-z SNe slightly closer than ΛCDM predicts
- Δχ² > 9 (3σ detection)
- Effective w(z) = -1 but ρ_Λ(z) ∝ (1+z)²

**Decision criterion**:
- |Δχ²| < 4: Inconclusive (need more data)
- Δχ² > 9: K-space favored (3σ)
- Δχ² < -9: ΛCDM favored (3σ)

### 1.6 Timeline and Resources

**Timeline**:
- Year 1-2: Survey, discover ~200 SNe
- Year 3-5: Continue survey, ~500 SNe total
- Year 6-10: Complete survey, ~1000 SNe total
- Year 11: Final analysis and publication

**Personnel**:
- 2 postdocs (data analysis)
- 1 graduate student (photometry pipeline)
- 1 senior scientist (PI)

**Computing**:
- 100 TB storage (images + catalogs)
- 1000 CPU-hours/year (fitting)

**Cost estimate**:
- Telescope time: Covered by existing surveys (Rubin, Euclid, Roman)
- Personnel: $500K/year × 10 years = $5M
- Computing: $50K/year × 10 years = $500K
- **Total: ~$5.5M over 10 years**

**Current status**: 
- Ongoing surveys (Rubin will provide data)
- Current constraint: w = -1.03 ± 0.03 (consistent with both models)
- Need z > 1.5 SNe for discrimination (Roman will reach z ~ 2.5)

### 1.7 Analysis Code Template

```python
import numpy as np
from scipy.optimize import minimize
from scipy.integrate import quad
import matplotlib.pyplot as plt

# Constants
c = 299792.458  # km/s

def luminosity_distance(z, H0, Omega_m, Omega_L, model='LCDM'):
    """
    Calculate luminosity distance for given cosmology.
    
    Parameters:
    - z: redshift
    - H0: Hubble constant (km/s/Mpc)
    - Omega_m: matter density parameter
    - Omega_L: dark energy density parameter
    - model: 'LCDM' or 'kspace'
    
    Returns:
    - d_L: luminosity distance in Mpc
    """
    def E_LCDM(zp):
        return np.sqrt(Omega_m*(1+zp)**3 + Omega_L)
    
    def E_kspace(zp):
        # Dark energy evolves as (1+z)²
        return np.sqrt(Omega_m*(1+zp)**3 + Omega_L*(1+zp)**2)
    
    E_func = E_LCDM if model == 'LCDM' else E_kspace
    
    integral, _ = quad(lambda zp: 1/E_func(zp), 0, z)
    d_L = (c/H0) * (1+z) * integral
    
    return d_L

def distance_modulus(z, H0, Omega_m, Omega_L, model='LCDM'):
    """Calculate distance modulus μ = m - M."""
    d_L = luminosity_distance(z, H0, Omega_m, Omega_L, model)
    mu = 5*np.log10(d_L) + 25  # Distance modulus
    return mu

def chi_squared(params, z_data, mu_data, sigma_data, model):
    """Calculate chi-squared for model fit."""
    H0, Omega_m, Omega_L = params
    
    mu_model = np.array([distance_modulus(z, H0, Omega_m, Omega_L, model) 
                         for z in z_data])
    
    chi2 = np.sum(((mu_data - mu_model)/sigma_data)**2)
    return chi2

# Example: Fit simulated data
if __name__ == "__main__":
    # Simulate data (replace with real observations)
    np.random.seed(42)
    z_sim = np.linspace(0.1, 2.0, 50)
    
    # True cosmology (k-space for this example)
    H0_true, Omega_m_true, Omega_L_true = 70.0, 0.3, 0.7
    mu_true = [distance_modulus(z, H0_true, Omega_m_true, Omega_L_true, 'kspace') 
               for z in z_sim]
    
    # Add noise
    sigma = 0.15  # Typical SN Ia uncertainty
    mu_obs = mu_true + np.random.normal(0, sigma, len(z_sim))
    sigma_obs = np.full(len(z_sim), sigma)
    
    # Fit both models
    initial_guess = [70, 0.3, 0.7]
    
    result_LCDM = minimize(chi_squared, initial_guess, 
                           args=(z_sim, mu_obs, sigma_obs, 'LCDM'),
                           method='Nelder-Mead')
    
    result_kspace = minimize(chi_squared, initial_guess,
                             args=(z_sim, mu_obs, sigma_obs, 'kspace'),
                             method='Nelder-Mead')
    
    # Compare
    chi2_LCDM = result_LCDM.fun
    chi2_kspace = result_kspace.fun
    Delta_chi2 = chi2_LCDM - chi2_kspace
    
    print(f"ΛCDM χ² = {chi2_LCDM:.2f}")
    print(f"K-space χ² = {chi2_kspace:.2f}")
    print(f"Δχ² = {Delta_chi2:.2f}")
    print(f"Significance: {np.sqrt(abs(Delta_chi2)):.1f}σ")
    
    if Delta_chi2 > 9:
        print("→ K-space model favored (3σ)")
    elif Delta_chi2 < -9:
        print("→ ΛCDM favored (3σ)")
    else:
        print("→ Inconclusive, need more data")
    
    # Plot
    z_plot = np.linspace(0.01, 2.0, 100)
    mu_LCDM = [distance_modulus(z, *result_LCDM.x, 'LCDM') for z in z_plot]
    mu_kspace = [distance_modulus(z, *result_kspace.x, 'kspace') for z in z_plot]
    
    plt.figure(figsize=(10, 6))
    plt.errorbar(z_sim, mu_obs, yerr=sigma_obs, fmt='ko', label='Simulated data')
    plt.plot(z_plot, mu_LCDM, 'r-', label='ΛCDM fit')
    plt.plot(z_plot, mu_kspace, 'b-', label='K-space fit')
    plt.xlabel('Redshift z')
    plt.ylabel('Distance Modulus μ')
    plt.legend()
    plt.title(f'SN Ia Hubble Diagram (Δχ² = {Delta_chi2:.1f})')
    plt.grid(True, alpha=0.3)
    plt.savefig('dark_energy_test.png', dpi=150)
    print("Plot saved: dark_energy_test.png")
```

---

## PROTOCOL 2: FINE STRUCTURE CONSTANT VARIATION

### 2.1 Scientific Rationale

**K-space prediction**:
```
α(z) = α(0) × (1 + z)
```

**Standard Model**:
```
α(z) = α(0) = 1/137.036... (exact constant)
```

**Discriminating power**: At z = 2 (10 Gyr ago):
- SM: α = α₀
- K-space: α = 3 × α₀

**Critical test**: Measure α at multiple redshifts using quasar absorption spectra.

### 2.2 Method: Many-Multiplet (MM) Method

**Principle**:
- Different atomic transitions have different sensitivity to α
- Transition wavelength: λ ∝ α^q (where q = sensitivity coefficient)
- Measure wavelength shifts → infer Δα/α

**Observable**: Relative wavelength shift
```
Δλ/λ = q × (Δα/α)
```

**Transitions used**:
- Fe II multiplets (q ~ 0 to 3)
- Mg II (q ~ 0.6)
- Si II (q ~ 0.8)
- Al III (q ~ 1.3)

### 2.3 Required Equipment

**Telescopes**:
- Keck 10m (HIRES spectrograph)
- VLT 8m (UVES spectrograph)
- Magellan 6.5m (MIKE spectrograph)
- Future: Extremely Large Telescope (ELT) 39m

**Spectrograph requirements**:
- Resolution: R > 40,000 (λ/Δλ)
- Wavelength coverage: 3000-10000 Å
- Stability: ±1 m/s (radial velocity precision)

**Calibration**:
- Thorium-Argon lamps (wavelength calibration)
- Laser frequency comb (ultimate precision)
- Simultaneous reference (fiber-fed)

**Data requirements**:
- ~100 quasars at 0.5 < z < 4
- Signal-to-noise > 20 per pixel
- Multiple metal absorption systems per quasar

### 2.4 Step-by-Step Procedure

**Step 1: Target Selection**
1. Query quasar catalogs (SDSS, 2dF)
2. Criteria:
   - Redshift z > 1
   - Bright enough: V < 18 mag
   - Known metal absorption systems
3. Verify with low-resolution preview spectrum
4. Select ~100 targets spanning z = 1-4

**Step 2: High-Resolution Spectroscopy**
1. Exposure time: 1-3 hours per quasar (depending on brightness)
2. Obtain spectrum with R > 40,000
3. Simultaneous calibration (ThAr or laser comb)
4. Multiple exposures per target (check consistency)

**Step 3: Data Reduction**
1. Bias subtraction (remove detector baseline)
2. Flat-field correction (pixel sensitivity)
3. Wavelength calibration (map pixels to λ)
   - Fit ThAr lines to polynomial
   - Typical RMS < 50 m/s
4. Sky subtraction (remove OH emission)
5. Extraction (optimal weighting)
6. Continuum fitting (normalize flux)

**Step 4: Absorption Line Identification**
1. Identify metal absorption systems
2. Common species: Fe II, Mg II, Si II, Al III, Zn II
3. Measure systemic redshift z_abs from multiple lines
4. Verify identification (wavelength ratios must match)

**Step 5: Line Profile Fitting**

For each transition:
1. Model as Voigt profile (convolution of Gaussian and Lorentzian)
2. Parameters:
   - Central wavelength λ_obs
   - Column density N
   - Doppler width b
   - Damping constant γ

Fit using χ² minimization:
```python
def voigt_profile(lambda_obs, lambda_0, N, b, gamma):
    """Voigt profile for absorption line."""
    # Doppler width
    sigma = lambda_0 * b / c
    # Lorentz width
    gamma_L = lambda_0 * gamma / (4*np.pi*c)
    # Voigt function (using Faddeeva)
    u = (lambda_obs - lambda_0) / sigma
    a = gamma_L / sigma
    profile = special.wofz(u + 1j*a).real / (sigma * np.sqrt(np.pi))
    # Optical depth
    tau = N * f * profile  # f = oscillator strength
    # Transmitted flux
    flux = np.exp(-tau)
    return flux
```

**Step 6: Alpha Variation Measurement**

Many-multiplet method:
1. Measure observed wavelength λ_obs for each transition
2. Predict wavelength: λ_pred = λ_rest × (1 + z_abs)
3. Measure offset: Δλ = λ_obs - λ_pred
4. For each transition i with sensitivity q_i:
   ```
   Δλ_i/λ_i = q_i × (Δα/α)
   ```
5. Fit for Δα/α using all transitions simultaneously

Weighted least squares:
```python
def fit_alpha_variation(lambda_obs, lambda_rest, q, sigma):
    """
    Fit Δα/α from multiple transitions.
    
    Parameters:
    - lambda_obs: observed wavelengths
    - lambda_rest: rest wavelengths
    - q: sensitivity coefficients
    - sigma: measurement uncertainties
    
    Returns:
    - Delta_alpha_over_alpha
    - uncertainty
    """
    Delta_lambda = lambda_obs - lambda_rest
    x = Delta_lambda / lambda_rest
    
    # Weighted fit: x = q × (Δα/α)
    weights = 1 / sigma**2
    Delta_alpha = np.sum(weights * x * q) / np.sum(weights * q**2)
    sigma_Delta_alpha = 1 / np.sqrt(np.sum(weights * q**2))
    
    return Delta_alpha, sigma_Delta_alpha
```

**Step 7: Systematic Error Analysis**

Critical systematics:
- **Isotopic abundance** (different isotopes shift lines)
- **Hyperfine structure** (unresolved components)
- **Line blending** (overlapping transitions)
- **Wavelength calibration** (ThAr drift)
- **Spectrograph distortions** (optical aberrations)

Mitigation strategies:
1. Use multiple absorption systems per quasar
2. Compare different atomic species
3. Use laser frequency comb calibration
4. Model isotope ratios explicitly
5. Monte Carlo simulations of systematic effects

**Step 8: Redshift Dependence Analysis**

Test k-space prediction:
```
α(z) / α(0) = 1 + z
```

Fit model:
```python
def alpha_evolution(z, model='kspace'):
    """Alpha evolution with redshift."""
    if model == 'kspace':
        return 1 + z  # K-space prediction
    else:
        return 1.0    # Standard Model (constant)

# Fit data
Delta_alpha_data = [...]  # From measurements
z_data = [...]
sigma_data = [...]

# Linear fit: Δα/α = A × z
A_fit = np.sum((Delta_alpha_data * z_data) / sigma_data**2) / \
        np.sum((z_data**2) / sigma_data**2)
sigma_A = 1 / np.sqrt(np.sum((z_data**2) / sigma_data**2))

print(f"Measured: Δα/α = ({A_fit:.2e} ± {sigma_A:.2e}) × z")
print(f"K-space predicts: Δα/α = z (A = 1)")
print(f"Deviation: {abs(A_fit - 1) / sigma_A:.1f}σ")
```

### 2.5 Expected Results

**If Standard Model is correct**:
- Δα/α consistent with zero at all z
- |Δα/α| < 10⁻⁶ (current observational limit)
- No trend with redshift

**If k-space is correct**:
- Δα/α increases linearly with z
- At z = 2: Δα/α ≈ 2 (α was 3× larger in past!)
- **This would be detected at >>10σ significance**

**Decision criterion**:
- |Δα/α| < 10⁻⁵ at z ~ 2: SM favored
- |Δα/α| ~ 1 at z ~ 2: K-space favored
- 10⁻⁵ < |Δα/α| < 0.1: New physics, neither model

**Current observational status**:
- Webb et al. (2011): Δα/α = (−0.57 ± 0.10) × 10⁻⁵ (tentative spatial dipole)
- Molaro et al. (2013): Δα/α = (0.0 ± 1.0) × 10⁻⁶ (consistent with constant)
- **Current limits rule out k-space prediction unless there's a selection effect**

### 2.6 Resolution of Apparent Contradiction

**The problem**: K-space predicts α(z) ∝ (1+z), but observations show α constant.

**Possible explanations**:

**Option 1**: K-space is wrong (falsified by this test)

**Option 2**: Measurement systematic (possible)
- Current methods assume all transitions scale identically
- If additional physics affects high-z measurements, could mask true variation
- Need independent confirmation

**Option 3**: Selection effect
- Quasars selected based on known redshifts
- If α changed, line positions shift
- Could we be missing high-z systems with very different α?

**Option 4**: Modification to k-space prediction
- Perhaps α evolution is:
  ```
  α(N) = α₀ × (N₀/N)^β where β < 1
  ```
- If β ~ 0.01, variation would be ~1% at z = 2 (potentially detectable)

**Critical test**: Use completely independent method (see Protocol 2.7)

### 2.7 Alternative Method: 21cm Absorption at High Redshift

**Principle**:
- 21cm hyperfine transition of neutral hydrogen
- Frequency: ν₂₁ ∝ α² (squared dependence)
- Compare to optical transitions at same z

**Observable**:
```
Δ(ν₂₁/ν_opt) / (ν₂₁/ν_opt) = 2 × (Δα/α)
```

**Advantages**:
- Different systematic errors than optical
- Radio interferometry (VLBI) has excellent precision
- Can reach very high z (cosmic dawn)

**Disadvantages**:
- Requires bright background radio source
- 21cm absorption systems rare
- Lower signal-to-noise than optical

**Facilities**:
- Square Kilometre Array (SKA) - under construction
- Very Large Array (VLA) - operational
- ALMA - operational (high-frequency end)

### 2.8 Timeline and Resources

**Timeline**:
- Year 1: Target selection, pilot observations (10 quasars)
- Year 2-3: Main survey (100 quasars)
- Year 4: Data analysis, systematic error studies
- Year 5: Publication

**Personnel**:
- 1 postdoc (spectroscopy expert)
- 1 graduate student (data reduction)
- 1 senior scientist (PI)

**Telescope time**:
- ~50 nights on 8-10m telescope
- Cost: $10K/night × 50 = $500K (opportunity cost)

**Computing**:
- 10 TB storage
- 100 CPU-hours (line fitting)

**Cost estimate**:
- Personnel: $300K/year × 5 years = $1.5M
- Telescope time: $500K (if not competitive award)
- Computing: $10K
- **Total: ~$2M over 5 years**

**Current status**:
- Ongoing surveys (Webb, Molaro groups)
- Current limit: Δα/α < 10⁻⁶ at z ~ 2
- K-space prediction (Δα/α ~ 1) ruled out unless systematic

---

## PROTOCOL 3: CONSCIOUSNESS COHERENCE MEASUREMENT

### 3.1 Scientific Rationale

**K-space prediction**:
```
C_conscious > 0.999  (spatial phase coherence)
C_unconscious < 0.99
```

**Standard Model**: No prediction (consciousness outside scope)

**Critical test**: Measure brain-wide phase coherence in different states of consciousness.

### 3.2 Method: EEG/MEG Phase-Locking Analysis

**Principle**:
- Neural oscillations create electromagnetic fields
- EEG measures scalp potentials (10-100 electrodes)
- MEG measures magnetic fields (100-300 sensors)
- Phase coherence = consistency of oscillation phases across brain

**Observable**: Global phase coherence
```
C = |⟨exp(iθ_k)⟩_k|
```
where θ_k = phase of oscillation at sensor k

### 3.3 Required Equipment

**EEG system**:
- High-density array: 128-256 electrodes
- Sampling rate: ≥1000 Hz
- Bit depth: 24-bit ADC
- Impedance: <5 kΩ per electrode
- Cost: $50K-100K

**MEG system** (preferred for higher precision):
- SQUID sensors: 306 channels
- Sampling rate: ≥1000 Hz
- Shielded room (magnetically isolated)
- Cost: $2M-3M (institutional facility)

**Auxiliary equipment**:
- Presentation computer (stimuli)
- Eye tracker (confirm state)
- Video monitoring
- Anesthesia equipment (for unconscious states)

### 3.4 Step-by-Step Procedure

**Step 1: Subject Recruitment**
1. N = 30 healthy volunteers (power analysis)
2. Exclusion criteria:
   - Neurological disorders
   - Psychiatric medications
   - Head injury history
3. IRB approval required
4. Informed consent

**Step 2: Experimental Design**

**States to measure**:
1. **Waking** (eyes open, alert)
2. **Meditation** (focused attention)
3. **Stage 2 sleep** (unconscious, light)
4. **Stage 3-4 sleep** (unconscious, deep)
5. **REM sleep** (dreaming)
6. **Anesthesia** (propofol, deeply unconscious)

**Session structure**:
- 10 min baseline (eyes open)
- 10 min meditation (guided)
- Overnight sleep recording (8 hours)
- Separate session: Anesthesia study (hospital setting)

**Step 3: Data Acquisition**

**EEG recording**:
1. Apply electrode cap
2. Inject conductive gel
3. Check impedances (<5 kΩ)
4. Record continuously
5. Mark state transitions (button press or automatic)

**MEG recording** (if available):
1. Position head in helmet
2. Localize head position (coils)
3. Record continuously
4. Co-register with MRI (anatomical)

**Step 4: Preprocessing**

```python
import mne
import numpy as np

# Load data
raw = mne.io.read_raw_fif('subject01_raw.fif', preload=True)

# Filter
raw.filter(1, 40, fir_design='firwin')  # 1-40 Hz bandpass

# Epoch by state
events = mne.find_events(raw)
epochs_awake = mne.Epochs(raw, events, event_id={'awake': 1}, 
                         tmin=0, tmax=10, baseline=None)
epochs_sleep = mne.Epochs(raw, events, event_id={'sleep': 2},
                         tmin=0, tmax=10, baseline=None)

# Artifact rejection
epochs_awake.drop_bad(reject=dict(eeg=100e-6))  # 100 μV threshold
```

**Step 5: Phase Extraction**

Hilbert transform method:
```python
from scipy.signal import hilbert

def extract_phases(epochs, freq_band=(8, 12)):
    """
    Extract instantaneous phases from EEG/MEG data.
    
    Parameters:
    - epochs: MNE epochs object
    - freq_band: (low, high) frequency range in Hz
    
    Returns:
    - phases: array of shape (n_epochs, n_channels, n_times)
    """
    # Filter to frequency band
    epochs_filt = epochs.copy().filter(freq_band[0], freq_band[1])
    
    # Get data
    data = epochs_filt.get_data()  # (n_epochs, n_channels, n_times)
    
    # Hilbert transform
    analytic_signal = hilbert(data, axis=2)
    
    # Extract phase
    phases = np.angle(analytic_signal)
    
    return phases
```

**Step 6: Coherence Calculation**

**Spatial coherence** (across channels):
```python
def spatial_coherence(phases):
    """
    Calculate global phase coherence across channels.
    
    C = |⟨exp(iθ)⟩_channels|
    
    Parameters:
    - phases: (n_epochs, n_channels, n_times)
    
    Returns:
    - C: coherence time series (n_epochs, n_times)
    """
    # Complex phasor
    phasors = np.exp(1j * phases)
    
    # Mean across channels
    mean_phasor = np.mean(phasors, axis=1)  # (n_epochs, n_times)
    
    # Magnitude = coherence
    C = np.abs(mean_phasor)
    
    return C
```

**Temporal coherence** (across time):
```python
def temporal_coherence(phases, window_size=100):
    """
    Calculate phase coherence within time windows.
    
    Parameters:
    - phases: (n_epochs, n_channels, n_times)
    - window_size: samples per window
    
    Returns:
    - C_temporal: (n_epochs, n_channels, n_windows)
    """
    n_epochs, n_channels, n_times = phases.shape
    n_windows = n_times // window_size
    
    C_temporal = np.zeros((n_epochs, n_channels, n_windows))
    
    for w in range(n_windows):
        start = w * window_size
        end = (w + 1) * window_size
        phase_window = phases[:, :, start:end]
        
        # Circular variance (1 - C)
        phasors = np.exp(1j * phase_window)
        mean_phasor = np.mean(phasors, axis=2)
        C_temporal[:, :, w] = np.abs(mean_phasor)
    
    return C_temporal
```

**Step 7: State Comparison**

For each subject:
1. Calculate mean coherence per state
2. Test threshold: Is C_conscious > 0.999?

Group statistics:
```python
def compare_states(C_awake, C_sleep, C_anesthesia):
    """
    Statistical comparison of coherence across states.
    
    Returns:
    - p_values: significance of differences
    - effect_sizes: Cohen's d
    """
    from scipy import stats
    
    # Paired t-tests
    t_awake_sleep, p_awake_sleep = stats.ttest_rel(C_awake, C_sleep)
    t_awake_anesth, p_awake_anesth = stats.ttest_rel(C_awake, C_anesthesia)
    
    # Effect sizes
    d_awake_sleep = (np.mean(C_awake) - np.mean(C_sleep)) / \
                    np.std(C_awake - C_sleep)
    
    d_awake_anesth = (np.mean(C_awake) - np.mean(C_anesthesia)) / \
                     np.std(C_awake - C_anesthesia)
    
    print(f"Awake vs Sleep: p = {p_awake_sleep:.4f}, d = {d_awake_sleep:.2f}")
    print(f"Awake vs Anesthesia: p = {p_awake_anesth:.4f}, d = {d_awake_anesth:.2f}")
    
    return {
        'p_values': (p_awake_sleep, p_awake_anesth),
        'effect_sizes': (d_awake_sleep, d_awake_anesth)
    }
```

**Step 8: Frequency-Specific Analysis**

Test different frequency bands:
- **Delta** (1-4 Hz): Deep sleep
- **Theta** (4-8 Hz): Drowsiness
- **Alpha** (8-12 Hz): Relaxed wakefulness
- **Beta** (12-30 Hz): Active thinking
- **Gamma** (30-100 Hz): Conscious perception

K-space prediction: Gamma band shows highest coherence in conscious states.

### 3.5 Expected Results

**If k-space is correct**:
- C_awake ≈ 0.99-1.00 (close to threshold)
- C_meditation > 0.999 (surpasses threshold)
- C_sleep < 0.95 (below threshold)
- C_anesthesia < 0.90 (well below threshold)
- Clear separation between conscious/unconscious states

**If k-space is wrong**:
- No consistent pattern across subjects
- Coherence doesn't correlate with consciousness
- Threshold 0.999 not special

**Alternative outcomes**:
- Threshold exists but at different value (e.g., 0.95)
- Coherence correlates but not perfectly (other factors matter)
- Frequency-specific (e.g., only gamma band relevant)

### 3.6 Systematic Considerations

**Confounds**:
- **Movement artifacts**: Head motion changes electrode positions
- **Muscle activity**: EMG contamination (especially awake)
- **Eye movements**: Large electrical artifacts
- **Electrode bridging**: Gel creates short circuits
- **Individual differences**: Anatomy, skull thickness

**Controls**:
- Independent component analysis (ICA) to remove artifacts
- Source localization (not just scalp sensors)
- Within-subject design (each person is their own control)
- Blind analysis (analyst doesn't know state)

### 3.7 Timeline and Resources

**Timeline**:
- Month 1-2: Equipment setup, pilot subjects (N=5)
- Month 3-6: Main data collection (N=30)
- Month 7-8: Data analysis
- Month 9: Manuscript preparation
- **Total: 9 months**

**Personnel**:
- 1 postdoc (EEG/MEG expert)
- 1 research assistant (data collection)
- 1 clinician (anesthesia sessions)
- 1 PI (oversight)

**Equipment**:
- EEG system: $100K (if purchasing new)
- Or use existing facility (typical university neuroscience department has one)

**Subject compensation**:
- $50/hour × 10 hours × 30 subjects = $15K

**Cost estimate**:
- Personnel: $150K/year × 0.75 years = $112K
- Equipment: $0 (use existing) or $100K (purchase)
- Subjects: $15K
- **Total: $130K (using existing equipment) or $230K (new equipment)**

**Feasibility**: HIGH - This is the most immediately testable prediction.

### 3.8 Current Evidence

**Existing literature**:
- Tononi's Integrated Information Theory: Consciousness correlates with φ (information integration)
- Dehaene's Global Workspace Theory: Consciousness requires widespread synchronization
- Anesthesia studies: All show decreased coherence/connectivity

**Closest existing work**:
- Casali et al. (2013): Perturbational Complexity Index (PCI) separates conscious/unconscious
- Sitt et al. (2014): Connectivity changes with consciousness level
- King et al. (2013): Loss of long-range coherence in anesthesia

**What's missing**:
- Nobody has tested specific threshold (0.999)
- Nobody has interpreted as k-space coherence
- K-space framework makes quantitative prediction, not just qualitative

**Next step**: Reanalyze existing datasets for exact coherence values.

---

## PROTOCOL 4: ENTANGLEMENT PATH TOPOLOGY

### 4.1 Scientific Rationale

**K-space prediction**:
```
Entanglement fidelity depends on k-space path, not x-space distance
F ∝ exp(-path_topology_complexity)
```

**Standard Model**:
```
Entanglement fidelity depends only on distance (decoherence)
F ∝ exp(-L/L_decoherence)
```

**Critical test**: Create entangled photons, send through curved vs straight paths of same length.

### 4.2 Method: Delayed-Choice Quantum Eraser with Path Curvature

**Setup**:
```
Source → Entangled pair (A, B)
         ↓              ↓
    Straight path   Curved path
         ↓              ↓
    Detector 1     Detector 2
```

Compare:
- **Condition 1**: Both photons travel straight paths
- **Condition 2**: Photon B travels curved path (fiber coiled, same total length)
- **Condition 3**: Both curved (different topologies)

Measure: Two-photon coincidence rate (entanglement fidelity)

### 4.3 Required Equipment

**Photon source**:
- Spontaneous parametric down-conversion (SPDC)
- Pump: 405 nm laser diode
- Nonlinear crystal: BBO (β-barium borate)
- Produces entangled pairs at 810 nm

**Path control**:
- Single-mode optical fiber
- Straight: Direct fiber, 10 m length
- Curved: Fiber wound in coils (various radii: 10 cm, 1 cm, 1 mm)
- Path length matching: <1 μm precision

**Detectors**:
- Single-photon avalanche photodiodes (SPADs)
- Timing resolution: <100 ps
- Dark count rate: <100 Hz
- Quantum efficiency: >50% at 810 nm

**Coincidence counting**:
- Time-to-digital converter (TDC)
- Time window: 1 ns
- Count rate: Up to 10⁶ /s

**Cost**: ~$200K for complete setup

### 4.4 Step-by-Step Procedure

**Step 1: System Calibration**

1. Align SPDC source:
   - Pump beam through BBO crystal
   - Collect down-converted photons in cones
   - Couple into fibers
   
2. Verify entanglement:
   - Measure Bell inequality (CHSH parameter)
   - Should violate by S > 2 (quantum) vs S ≤ 2 (classical)
   - Target: S ≈ 2.7

3. Path length matching:
   - Use Hong-Ou-Mandel interference
   - Adjust fiber lengths until dip in coincidences
   - Precision: <10 μm

**Step 2: Baseline Measurement (Straight Paths)**

Configuration: Both photons travel straight 10 m fibers

1. Record coincidence counts for 1 hour
2. Calculate fidelity:
   ```
   F = (C_++ + C_-- - C_+- - C_-+) / (C_++ + C_-- + C_+- + C_-+)
   ```
   where C_ij = coincidence rate in basis states i,j

3. Repeat 10 times (statistical error)

**Step 3: Curved Path Measurement**

Configuration: Photon B through curved fiber (same length)

Curvature variations:
- Coil radius R = 10 cm (gentle curve)
- Coil radius R = 1 cm (tight curve)
- Coil radius R = 1 mm (extreme curve)

For each curvature:
1. Wind fiber around cylinder of radius R
2. Ensure total length still 10 m (path length matching critical)
3. Measure coincidence rates (1 hour)
4. Calculate fidelity F_curved

**Step 4: Topology Characterization**

Quantify path topology:
- **Straight path**: Topology = 0 (trivial)
- **Curved path**: Topology = ∫ κ(s) ds (total curvature)
  where κ = 1/R = curvature, s = arc length

For coil of radius R with N loops:
```
Total curvature = N × (2π) × (1/R)
```

**Step 5: Data Analysis**

Test k-space prediction:
```
F = F_0 × exp(-α × Topology)
```

vs Standard Model:
```
F = F_0 × exp(-L / L_decoherence)
```

Since L is fixed (10 m in all cases), SM predicts F = constant.

Fit exponential:
```python
def fit_topology_dependence(topology, fidelity, fidelity_err):
    """
    Fit F = F_0 × exp(-α × T)
    
    Parameters:
    - topology: array of topology measures
    - fidelity: measured fidelities
    - fidelity_err: uncertainties
    
    Returns:
    - F_0: baseline fidelity
    - alpha: topology sensitivity
    - chi2: goodness of fit
    """
    from scipy.optimize import curve_fit
    
    def model(T, F0, alpha):
        return F0 * np.exp(-alpha * T)
    
    popt, pcov = curve_fit(model, topology, fidelity, 
                          sigma=fidelity_err, absolute_sigma=True)
    
    F0, alpha = popt
    F0_err, alpha_err = np.sqrt(np.diag(pcov))
    
    # Chi-squared
    F_pred = model(topology, F0, alpha)
    chi2 = np.sum(((fidelity - F_pred) / fidelity_err)**2)
    dof = len(topology) - 2
    
    print(f"F_0 = {F0:.4f} ± {F0_err:.4f}")
    print(f"α = {alpha:.2e} ± {alpha_err:.2e}")
    print(f"χ²/dof = {chi2:.2f}/{dof}")
    
    return F0, alpha, chi2
```

**Step 6: Control Measurements**

**Control 1: Temperature**
- Curved fibers might heat due to bending stress
- Monitor temperature with thermocouples
- Repeat measurements at different ambient T

**Control 2: Polarization**
- Bending can induce birefringence
- Check polarization state before/after curve
- Use polarization-maintaining fiber

**Control 3: Path length**
- Slight length mismatch could cause reduced visibility
- Scan path length ±100 μm around match point
- Verify visibility peak unchanged

**Control 4: Decoherence**
- Longer fibers should reduce F (even if straight)
- Measure F vs length: 1 m, 10 m, 100 m (straight)
- Confirm standard decoherence scaling

### 4.5 Expected Results

**If Standard Model is correct**:
- F independent of curvature (same length → same decoherence)
- α = 0 (no topology dependence)
- F drops only with total path length

**If k-space is correct**:
- F decreases with increasing curvature
- α > 0 (topology matters)
- Tight coils (R = 1 mm) show significant F reduction

**Quantitative k-space prediction**:
- At R = 10 cm, N = 15 loops: Topology ≈ 1000 rad
- If α ~ 10⁻⁴ rad⁻¹: F ≈ 0.9 × F_straight (10% reduction)
- At R = 1 mm, N = 1500 loops: Topology ≈ 10⁷ rad
- F ≈ 0 (entanglement destroyed)

**Decision criterion**:
- |α| < 10⁻⁶: SM favored (no effect)
- α > 10⁻⁴: K-space favored (clear effect)
- 10⁻⁶ < α < 10⁻⁴: Marginal (need more precision)

### 4.6 Systematic Errors

**Fiber birefringence**:
- Bending induces polarization rotation
- Could reduce visibility without affecting entanglement
- **Mitigation**: Use polarization-maintaining fiber

**Thermal effects**:
- Coiled fiber heats up slightly
- Ther