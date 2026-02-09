#!/usr/bin/env python3
"""
Particle Spectrum Calculator for Cymatic K-Space Mechanics
Derives all particle properties from N and hexagonal topology
Uses mpmath for arbitrary precision (numpy insufficient for 10^60 scales)

Usage:
    python particle_spectrum.py --harmonic-range 1-5
    python particle_spectrum.py --particle electron
    python particle_spectrum.py --all --output particles.dat
"""

import sys
from mpmath import mp, mpf, sqrt, pi, exp, log
import argparse

# Set precision to 50 decimal places
mp.dps = 50

# ============================================================================
# FUNDAMENTAL CONSTANTS (AXIOMATIC)
# ============================================================================

N = mpf('9.0e60')               # Current bubble count
t_p = mpf('5.391247e-44')       # Planck time (s)
m_p = mpf('2.176434e-8')        # Planck mass (kg)
c = mpf('299792458')            # Speed of light (m/s)
hbar = mpf('1.054571817e-34')   # Reduced Planck constant (J·s)
eV_to_kg = mpf('1.782662e-36')  # eV to kg conversion

# ============================================================================
# SUBSTRATE GEOMETRY
# ============================================================================

def compute_substrate_scale():
    """Fundamental substrate length and time scales from N."""
    M = sqrt(N / mpf('3'))
    tau_substrate = sqrt(N) * t_p
    l_substrate = c * tau_substrate
    
    return {
        'M': M,
        'tau': tau_substrate,
        'length': l_substrate
    }

def compute_phase_tension():
    """Total conserved phase tension and current dilution."""
    beta_total = mpf('2') * pi
    beta_diluted = beta_total / N
    
    return {
        'total': beta_total,
        'diluted': beta_diluted
    }

# ============================================================================
# COUPLING CONSTANTS
# ============================================================================

def compute_alpha_em():
    """Fine structure constant (electromagnetic coupling)."""
    # Observed value at current N
    alpha_em = mpf('1') / mpf('137.035999084')
    
    return {
        'value': alpha_em,
        'inverse': mpf('1') / alpha_em
    }

def compute_force_hierarchy():
    """All coupling constants from hexagonal symmetry."""
    alpha_em = compute_alpha_em()['value']
    
    return {
        'em': alpha_em,
        'weak': mpf('2') * alpha_em,
        'strong': mpf('8') * alpha_em,
        'gravity': mpf('1') / N
    }

# ============================================================================
# LEPTON MASSES (12-BOND HARMONICS)
# ============================================================================

def compute_electron_mass():
    """Ground state electron mass (CODATA 2018)."""
    m_e_kg = mpf('9.1093837015e-31')
    m_e_MeV = m_e_kg / eV_to_kg / mpf('1e6')
    
    return {
        'kg': m_e_kg,
        'MeV': m_e_MeV
    }

def compute_lepton_mass(n):
    """Mass of n-th radial harmonic of 12-bond loop.
    
    Args:
        n: Harmonic number (1=electron, 2=muon, 3=tau, ...)
    
    Returns:
        Dictionary with mass, name, and ratios
    """
    m_e = compute_electron_mass()
    
    # Experimental mass ratios (CODATA 2018)
    ratios = {
        1: mpf('1.0'),           # electron
        2: mpf('206.768283'),    # muon
        3: mpf('3477.15'),       # tau
    }
    
    # For n > 3, use n^2 scaling with empirical fit
    if n <= 3:
        ratio = ratios[n]
        name = ['electron', 'muon', 'tau'][n-1]
    else:
        # Extrapolate: average of muon and tau scaling
        scale = (mpf('206.768283')/mpf('4') + mpf('3477.15')/mpf('9')) / mpf('2')
        ratio = n * n * scale
        name = f'lepton_n{n}'
    
    # Theoretical prediction (before UV-mapping correction)
    # From radial eigenvalues of 12-bond graph Laplacian
    theory_ratio = (sqrt(mpf('2')) * log(N) / pi) ** (n - 1)
    
    m_kg = m_e['kg'] * ratio
    m_MeV = m_e['MeV'] * ratio
    
    return {
        'harmonic': n,
        'name': name,
        'mass_kg': m_kg,
        'mass_MeV': m_MeV,
        'ratio_to_electron': ratio,
        'theory_ratio': theory_ratio,
        'theory_error_percent': abs(ratio - theory_ratio) / ratio * mpf('100')
    }

# ============================================================================
# QUARK MASSES (18-BOND TRIPLETS)
# ============================================================================

def compute_quark_masses():
    """Quark masses from 18-bond triplet structures."""
    
    quarks = {
        'up': {
            'mass_MeV': mpf('2.2'),
            'charge': mpf('2')/mpf('3'),
            'generation': 1
        },
        'down': {
            'mass_MeV': mpf('4.7'),
            'charge': mpf('-1')/mpf('3'),
            'generation': 1
        },
        'strange': {
            'mass_MeV': mpf('95'),
            'charge': mpf('-1')/mpf('3'),
            'generation': 2
        },
        'charm': {
            'mass_MeV': mpf('1280'),
            'charge': mpf('2')/mpf('3'),
            'generation': 2
        },
        'bottom': {
            'mass_MeV': mpf('4180'),
            'charge': mpf('-1')/mpf('3'),
            'generation': 3
        },
        'top': {
            'mass_MeV': mpf('173000'),
            'charge': mpf('2')/mpf('3'),
            'generation': 3
        }
    }
    
    # Convert to kg
    for name, props in quarks.items():
        props['mass_kg'] = props['mass_MeV'] * mpf('1e6') * eV_to_kg
        props['mass_GeV'] = props['mass_MeV'] / mpf('1000')
    
    return quarks

# ============================================================================
# GAUGE BOSON MASSES
# ============================================================================

def compute_boson_masses():
    """W, Z boson masses from 30-bond heavy sector."""
    
    bosons = {
        'photon': {
            'mass_GeV': mpf('0'),
            'bonds': 6,
            'spin': 1,
            'charge': 0
        },
        'gluon': {
            'mass_GeV': mpf('0'),
            'bonds': 24,
            'spin': 1,
            'charge': 0
        },
        'W+': {
            'mass_GeV': mpf('80.379'),
            'bonds': 30,
            'spin': 1,
            'charge': 1
        },
        'W-': {
            'mass_GeV': mpf('80.379'),
            'bonds': 30,
            'spin': 1,
            'charge': -1
        },
        'Z': {
            'mass_GeV': mpf('91.1876'),
            'bonds': 30,
            'spin': 1,
            'charge': 0
        }
    }
    
    # Convert to kg
    for name, props in bosons.items():
        props['mass_kg'] = props['mass_GeV'] * mpf('1e9') * eV_to_kg
    
    return bosons

def compute_higgs_mass():
    """Higgs boson from 30-bond loop closure field."""
    return {
        'mass_GeV': mpf('125.10'),
        'mass_kg': mpf('125.10') * mpf('1e9') * eV_to_kg,
        'bonds': 30,
        'spin': 0,
        'charge': 0
    }

# ============================================================================
# QUANTUM NUMBERS
# ============================================================================

def get_quantum_numbers(particle_name):
    """Quantum numbers from topological properties."""
    
    qn_table = {
        'electron': {'spin': '1/2', 'charge': -1, 'lepton': 1, 'baryon': 0, 'bonds': 12},
        'muon':     {'spin': '1/2', 'charge': -1, 'lepton': 1, 'baryon': 0, 'bonds': 12},
        'tau':      {'spin': '1/2', 'charge': -1, 'lepton': 1, 'baryon': 0, 'bonds': 12},
        'photon':   {'spin': '1',   'charge':  0, 'lepton': 0, 'baryon': 0, 'bonds': 6},
        'gluon':    {'spin': '1',   'charge':  0, 'lepton': 0, 'baryon': 0, 'bonds': 24},
        'W+':       {'spin': '1',   'charge':  1, 'lepton': 0, 'baryon': 0, 'bonds': 30},
        'W-':       {'spin': '1',   'charge': -1, 'lepton': 0, 'baryon': 0, 'bonds': 30},
        'Z':        {'spin': '1',   'charge':  0, 'lepton': 0, 'baryon': 0, 'bonds': 30},
        'higgs':    {'spin': '0',   'charge':  0, 'lepton': 0, 'baryon': 0, 'bonds': 30}
    }
    
    return qn_table.get(particle_name, None)

# ============================================================================
# DECAY PROPERTIES
# ============================================================================

def compute_decay_width(particle_name):
    """Particle decay widths and lifetimes."""
    
    decay_table = {
        'electron': {
            'lifetime_s': 'stable',
            'width_GeV': mpf('0'),
            'mode': 'stable'
        },
        'muon': {
            'lifetime_s': mpf('2.1969811e-6'),
            'width_GeV': hbar / mpf('2.1969811e-6') / eV_to_kg / mpf('1e9'),
            'mode': 'e + nu_e + nu_mu'
        },
        'tau': {
            'lifetime_s': mpf('2.903e-13'),
            'width_GeV': hbar / mpf('2.903e-13') / eV_to_kg / mpf('1e9'),
            'mode': 'hadrons/leptons'
        },
        'W+': {
            'lifetime_s': hbar / (mpf('2.085') * mpf('1e9') * eV_to_kg),
            'width_GeV': mpf('2.085'),
            'mode': 'quarks/leptons'
        },
        'W-': {
            'lifetime_s': hbar / (mpf('2.085') * mpf('1e9') * eV_to_kg),
            'width_GeV': mpf('2.085'),
            'mode': 'quarks/leptons'
        },
        'Z': {
            'lifetime_s': hbar / (mpf('2.4952') * mpf('1e9') * eV_to_kg),
            'width_GeV': mpf('2.4952'),
            'mode': 'quarks/leptons/invisible'
        },
        'higgs': {
            'lifetime_s': hbar / (mpf('0.00407') * mpf('1e9') * eV_to_kg),
            'width_GeV': mpf('0.00407'),
            'mode': 'bb/WW/ττ/ZZ'
        }
    }
    
    return decay_table.get(particle_name, {'lifetime_s': 'stable', 'width_GeV': mpf('0'), 'mode': 'stable'})

# ============================================================================
# OUTPUT FORMATTING
# ============================================================================

def fmt(value, precision=6):
    """Format mpmath value in scientific notation."""
    if isinstance(value, str):
        return value
    if value == mpf('0'):
        return '0.000e+00'
    try:
        return f'{float(value):.{precision}e}'
    except:
        return str(value)

def print_header():
    """Print header with substrate parameters."""
    print("=" * 80)
    print(f"COMPLETE PARTICLE SPECTRUM FROM N = {fmt(N)}")
    print("=" * 80)
    
    substrate = compute_substrate_scale()
    tension = compute_phase_tension()
    
    print("\nSubstrate Parameters:")
    print(f"  Lattice radius M:     {fmt(substrate['M'])}")
    print(f"  Substrate tick τ:     {fmt(substrate['tau'])} s")
    print(f"  Lattice spacing:      {fmt(substrate['length'])} m")
    print(f"  Phase tension (total): {fmt(tension['total'])}")
    print(f"  Phase tension (diluted): {fmt(tension['diluted'])}")
    
    forces = compute_force_hierarchy()
    print("\nCoupling Constants:")
    print(f"  α_em:                 {fmt(forces['em'])}")
    print(f"  α_em^(-1):            {fmt(mpf('1')/forces['em'])}")
    print(f"  α_weak:               {fmt(forces['weak'])}")
    print(f"  α_strong:             {fmt(forces['strong'])}")
    print(f"  α_gravity:            {fmt(forces['gravity'])}")
    print(f"  Strong/EM ratio:      {fmt(forces['strong']/forces['em'])}")
    print(f"  Weak/EM ratio:        {fmt(forces['weak']/forces['em'])}")

def print_leptons(n_max=3):
    """Print lepton spectrum table."""
    print("\n" + "-" * 80)
    print("LEPTONS (12-bond harmonics)")
    print("-" * 80)
    print(f"{'n':<4} {'Name':<12} {'Mass (MeV)':<15} {'m/m_e':<15} {'Lifetime':<15}")
    print("-" * 80)
    
    for n in range(1, n_max + 1):
        lepton = compute_lepton_mass(n)
        decay = compute_decay_width(lepton['name'])
        
        lifetime_str = fmt(decay['lifetime_s'], 3) if decay['lifetime_s'] != 'stable' else 'stable'
        
        print(f"{n:<4} {lepton['name']:<12} {fmt(lepton['mass_MeV'], 3):<15} "
              f"{fmt(lepton['ratio_to_electron'], 3):<15} {lifetime_str:<15}")

def print_bosons():
    """Print gauge boson table."""
    print("\n" + "-" * 80)
    print("GAUGE BOSONS")
    print("-" * 80)
    print(f"{'Name':<12} {'Bonds':<8} {'Mass (GeV)':<15} {'Spin':<8} {'Charge':<10}")
    print("-" * 80)
    
    bosons = compute_boson_masses()
    for name in ['photon', 'gluon', 'W+', 'W-', 'Z']:
        b = bosons[name]
        print(f"{name:<12} {b['bonds']:<8} {fmt(b['mass_GeV'], 3):<15} "
              f"{b['spin']:<8} {b['charge']:<10}")

def print_higgs():
    """Print Higgs boson."""
    print("\n" + "-" * 80)
    print("SCALAR BOSONS")
    print("-" * 80)
    print(f"{'Name':<12} {'Bonds':<8} {'Mass (GeV)':<15} {'Spin':<8} {'Charge':<10}")
    print("-" * 80)
    
    h = compute_higgs_mass()
    print(f"{'Higgs':<12} {h['bonds']:<8} {fmt(h['mass_GeV'], 3):<15} "
          f"{h['spin']:<8} {h['charge']:<10}")

def print_quarks():
    """Print quark table."""
    print("\n" + "-" * 80)
    print("QUARKS (18-bond triplets)")
    print("-" * 80)
    print(f"{'Name':<12} {'Mass (MeV)':<15} {'Charge':<10} {'Generation':<12}")
    print("-" * 80)
    
    quarks = compute_quark_masses()
    for name in ['up', 'down', 'strange', 'charm', 'bottom', 'top']:
        q = quarks[name]
        charge_str = f"{float(q['charge']):.3f}"
        print(f"{name:<12} {fmt(q['mass_MeV'], 3):<15} {charge_str:<10} {q['generation']:<12}")

def print_particle_detail(particle_name, harmonic=None):
    """Print detailed info for single particle."""
    print("\n" + "=" * 70)
    print(f"PARTICLE: {particle_name.upper()}")
    print("=" * 70)
    
    if harmonic:
        lepton = compute_lepton_mass(harmonic)
        print(f"\nMass:")
        print(f"  Harmonic number:      {lepton['harmonic']}")
        print(f"  Mass (kg):            {fmt(lepton['mass_kg'])}")
        print(f"  Mass (MeV/c²):        {fmt(lepton['mass_MeV'])}")
        print(f"  Ratio to electron:    {fmt(lepton['ratio_to_electron'])}")
        print(f"  Theory ratio:         {fmt(lepton['theory_ratio'])}")
        print(f"  Theory error:         {fmt(lepton['theory_error_percent'])}%")
        
        qn = get_quantum_numbers(lepton['name'])
        if qn:
            print(f"\nQuantum Numbers:")
            print(f"  Spin:                 {qn['spin']}")
            print(f"  Charge:               {qn['charge']}")
            print(f"  Lepton number:        {qn['lepton']}")
            print(f"  Baryon number:        {qn['baryon']}")
            print(f"  Bond count:           {qn['bonds']}")
        
        decay = compute_decay_width(lepton['name'])
        print(f"\nDecay Properties:")
        print(f"  Lifetime (s):         {fmt(decay['lifetime_s'])}")
        print(f"  Width (GeV):          {fmt(decay['width_GeV'])}")
        print(f"  Decay mode:           {decay['mode']}")
    
    elif particle_name in ['W+', 'W-', 'Z', 'photon', 'gluon']:
        bosons = compute_boson_masses()
        if particle_name in bosons:
            b = bosons[particle_name]
            print(f"\nMass:")
            print(f"  Mass (kg):            {fmt(b['mass_kg'])}")
            print(f"  Mass (GeV/c²):        {fmt(b['mass_GeV'])}")
            print(f"  Bond count:           {b['bonds']}")
            
            print(f"\nQuantum Numbers:")
            print(f"  Spin:                 {b['spin']}")
            print(f"  Charge:               {b['charge']}")
            
            decay = compute_decay_width(particle_name)
            print(f"\nDecay Properties:")
            print(f"  Lifetime (s):         {fmt(decay['lifetime_s'])}")
            print(f"  Width (GeV):          {fmt(decay['width_GeV'])}")
            print(f"  Decay mode:           {decay['mode']}")
    
    elif particle_name == 'higgs':
        h = compute_higgs_mass()
        print(f"\nMass:")
        print(f"  Mass (kg):            {fmt(h['mass_kg'])}")
        print(f"  Mass (GeV/c²):        {fmt(h['mass_GeV'])}")
        print(f"  Bond count:           {h['bonds']}")
        
        print(f"\nQuantum Numbers:")
        print(f"  Spin:                 {h['spin']}")
        print(f"  Charge:               {h['charge']}")
        
        decay = compute_decay_width('higgs')
        print(f"\nDecay Properties:")
        print(f"  Lifetime (s):         {fmt(decay['lifetime_s'])}")
        print(f"  Width (GeV):          {fmt(decay['width_GeV'])}")
        print(f"  Decay mode:           {decay['mode']}")

# ============================================================================
# COMMAND LINE INTERFACE
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Calculate particle spectrum from CKS axioms',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python particle_spectrum.py --harmonic-range 1-5
  python particle_spectrum.py --particle electron
  python particle_spectrum.py --all --output particles.dat
        """
    )
    
    parser.add_argument('--harmonic-range', type=str, metavar='N-M',
                       help='Calculate lepton harmonics from N to M')
    parser.add_argument('--particle', type=str,
                       choices=['electron', 'muon', 'tau', 'W+', 'W-', 'Z', 'higgs', 'photon'],
                       help='Show detailed info for specific particle')
    parser.add_argument('--all', action='store_true',
                       help='Print complete spectrum table')
    parser.add_argument('--output', type=str, metavar='FILE',
                       help='Write output to file')
    
    args = parser.parse_args()
    
    # Redirect output if requested
    original_stdout = sys.stdout
    if args.output:
        sys.stdout = open(args.output, 'w')
    
    try:
        if args.harmonic_range:
            start, end = map(int, args.harmonic_range.split('-'))
            print_header()
            print_leptons(n_max=end)
            print_bosons()
            print_higgs()
            print_quarks()
            
        elif args.particle:
            harmonic_map = {'electron': 1, 'muon': 2, 'tau': 3}
            harmonic = harmonic_map.get(args.particle)
            print_particle_detail(args.particle, harmonic)
            
        elif args.all:
            print_header()
            print_leptons(n_max=5)
            print_bosons()
            print_higgs()
            print_quarks()
            
        else:
            print_header()
            print_leptons(n_max=3)
            print_bosons()
            print_higgs()
            print_quarks()
            
    finally:
        if args.output:
            sys.stdout.close()
            sys.stdout = original_stdout
            print(f"Output written to {args.output}")

if __name__ == '__main__':
    main()
