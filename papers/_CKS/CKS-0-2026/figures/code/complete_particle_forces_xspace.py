import numpy as np
from kspace import KSpaceSubstrate

sub = KSpaceSubstrate(N='9e60')

# SI projections (GeV or dimensionless)
data = [
    # Particle/Boson,  Mass_GeV,  Charge,  Coupling_Inv,  Description
    ('Electron',        0.00051099895,  -1,    137.0359990847,  'lepton'),
    ('Muon',            0.105658375,     -1,    137.0359990847,  'lepton'),
    ('Tau',             1.77686,         -1,    137.0359990847,  'lepton'),
    ('Photon',          0.0,              0,    137.0359990847,  'photon'),
    ('Gluon',           0.330,              0,    8.45,           'gluon'),
    ('W',               80.4,            -1,    29.3,           'weak boson'),
    ('Z',               91.2,             0,    29.3,           'weak boson'),
    ('Higgs',           125.1,            0,    29.3,           'scalar boson'),
    ('Up_Quark',        0.0023,          2/3,  8.45,           'quark'),
    ('Down_Quark',      0.0048,         -1/3,  8.45,           'quark'),
    ('Neutrino_1',      5.8e-11,          0,    137.0359990847,  'neutrino'),
]

with open('complete_particle_forces_xspace.dat', 'w') as f:
    f.write('# Particle/Boson  Mass_GeV  Charge  Coupling_Inv  Description\n')
    for name, mass, charge, coup, desc in data:
        f.write(f'{name}  {mass:.6f}  {charge:.3f}  {coup:.6f}  {desc}\n')

