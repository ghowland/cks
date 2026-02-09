import matplotlib.pyplot as plt
import numpy as np
from kspace import KSpaceSubstrate
import mpmath as mp

# Consciousness coherence vs bubble count
N_vals = np.logspace(58, 62, 100)
C_vals = []
for n in N_vals:
    sub = KSpaceSubstrate(N=str(int(n)))
    C = sub.consciousness_coherence()
    C_vals.append(float(C))

fig, ax = plt.subplots(figsize=(5,3.5))
ax.semilogx(N_vals, C_vals, color='teal', lw=2.5)
ax.axhline(0.999, color='crimson', ls='--', lw=2, label='Consciousness threshold')
ax.set_xlabel('Bubble count N')
ax.set_ylabel('Coherence C')
ax.set_title('Consciousness Emergence', fontsize=11)
ax.legend(fontsize=10)
ax.grid(True, which="both", ls="--", alpha=0.3)
plt.tight_layout()
plt.savefig('consciousness_coherence.png', dpi=300, bbox_inches='tight')
plt.close()
