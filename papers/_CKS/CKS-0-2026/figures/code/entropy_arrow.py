import matplotlib.pyplot as plt
import numpy as np
from kspace import KSpaceSubstrate
import mpmath as mp

# Entropy rate vs cosmic age
t_vals = np.logspace(10, 18, 100)  # age in seconds
N_vals = 3e8 * t_vals / 1.616e-35   # N(t) = ct/l_P
dS_dN = 1 / N_vals                    # dS/dN = 1/N
dS_dt = dS_dN * (1 / 1.616e-35)      # dS/dt = (1/N) × (dN/dt)

fig, ax = plt.subplots(figsize=(5,3.5))
ax.loglog(t_vals, dS_dt, color='darkgreen', lw=2.5)
ax.set_xlabel('Cosmic age t (s)')
ax.set_ylabel('Entropy rate dS/dt (bit/s)')
ax.set_title('Arrow of Time (Entropy Increase)', fontsize=11)
ax.grid(True, which="both", ls="--", alpha=0.3)
plt.tight_layout()
plt.savefig('entropy_arrow.png', dpi=300, bbox_inches='tight')
plt.close()

