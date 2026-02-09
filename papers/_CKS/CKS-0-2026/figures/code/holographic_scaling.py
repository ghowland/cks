import matplotlib.pyplot as plt
import numpy as np

# Holographic scaling: Surface vs Bulk vs Observable
N_vals = np.logspace(60, 65, 50)                  # bubble count
M = np.sqrt(N_vals / 3)                           # lattice side
Surface = 6 * M                                   # surface bubbles ∝ N^(1/2)
Bulk = N_vals - Surface                           # bulk bubbles ∝ N
Observable = Surface / (N_vals**(2/3))              # observable ∝ N^(2/3)

fig, ax = plt.subplots(figsize=(5,3.5))
ax.loglog(N_vals, Surface/N_vals, label='Surface fraction ∝ N^(-1/2)', lw=2.5)
ax.loglog(N_vals, Observable, label='Observable scaling ∝ N^(2/3)', lw=2.5)
ax.set_xlabel('Bubble count N')
ax.set_ylabel('Fraction / Scaling')
ax.legend(fontsize=10)
ax.grid(True, which="both", ls="--", alpha=0.3)
plt.tight_layout()
plt.savefig('holographic_scaling.png', dpi=300, bbox_inches='tight')
plt.close()

