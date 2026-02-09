import numpy as np
import mpmath as mp
from kspace import KSpaceSubstrate

sub = KSpaceSubstrate(N='9e60')
M = mp.sqrt(sub.N / 3)

# Mechanical counts (k-space units)
data = [
    # Particle/Boson,  Bonds,  Spin,  Charge,  lambda_kspace,  Description
    ('Electron',       12,     0.5,   -1,    float((6 * M * mp.log(sub.N) * mp.exp(1)) / (12 * mp.pi)),   '12-bond fermion'),
    ('Muon',           12,     0.5,   -1,    float((6 * M * mp.log(sub.N) * mp.exp(1)) / (12 * mp.pi)),   '12-bond fermion'),
    ('Tau',            12,     0.5,   -1,    float((6 * M * mp.log(sub.N) * mp.exp(1)) / (12 * mp.pi)),   '12-bond fermion'),
    ('Photon',          6,     1,     0,    float((6 * M * mp.log(sub.N) * mp.exp(1)) / (6 * mp.pi)),   '6-bond boson'),
    ('Gluon',           24,     1,     0,    float((6 * M * mp.log(sub.N) * mp.exp(1)) / (24 * mp.pi)),   '24-bond boson'),
    ('W',               30,     1,   -1,    float((6 * M * mp.log(sub.N) * mp.exp(1)) / (30 * mp.pi)),   '30-bond boson'),
    ('Z',               30,     1,     0,    float((6 * M * mp.log(sub.N) * mp.exp(1)) / (30 * mp.pi)),   '30-bond boson'),
    ('Higgs',           30,     0,     0,    float((6 * M * mp.log(sub.N) * mp.exp(1)) / (30 * mp.pi)),   '30-bond scalar'),
    ('Up_Quark',        18,     0.5,  2/3,   float((6 * M * mp.log(sub.N) * mp.exp(1)) / (18 * mp.pi)),   '18-bond fermion'),
    ('Down_Quark',      18,     0.5,  -1/3,  float((6 * M * mp.log(sub.N) * mp.exp(1)) / (18 * mp.pi)),   '18-bond fermion'),
    ('Neutrino_1',       6,     0.5,    0,    float((6 * M * mp.log(sub.N) * mp.exp(1)) / (6 * mp.pi)),   '6-bond fermion (null winding)'),
]

with open('complete_particle_forces_kspace.dat', 'w') as f:
    f.write('# Particle/Boson  Bonds  Spin  Charge  lambda_kspace  Description\n')
    for name, bonds, spin, charge, lam, desc in data:
        f.write(f'{name}  {bonds}  {spin:.1f}  {charge:.3f}  {lam:.6e}  {desc}\n')

