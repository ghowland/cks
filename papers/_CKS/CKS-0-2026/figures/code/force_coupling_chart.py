import matplotlib.pyplot as plt
import numpy as np
from kspace import KSpaceSubstrate

sub = KSpaceSubstrate(N='9e60')

forces = ['Electromagnetic', 'Weak', 'Strong']
couplings_inv = [
    137.0359990847,   # α_em^(-1)
    29.3,             # α_w^(-1)
    8.45              # α_s^(-1)
]

fig, ax = plt.subplots(figsize=(4,3))
x = np.arange(len(forces))
ax.bar(x, couplings_inv, color=['gold', 'orange', 'red'], edgecolor='black', lw=1)
ax.set_xticks(x)
ax.set_xticklabels(forces, fontsize=10)
ax.set_ylabel('1 / α (dimensionless)', fontsize=10)
ax.set_title('Force Coupling Constants (Mechanical)', fontsize=11)
ax.grid(True, axis='y', ls="--", alpha=0.3)
for i, v in enumerate(couplings_inv):
    ax.text(i, v + 2, f'{v:.2f}', ha='center', va='bottom', fontsize=9)
plt.tight_layout()
plt.savefig('force_coupling_chart.png', dpi=300, bbox_inches='tight')
plt.close()


