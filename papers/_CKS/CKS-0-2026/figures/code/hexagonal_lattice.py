import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import RegularPolygon

# k-space hexagonal lattice (bubble substrate)
fig, ax = plt.subplots(figsize=(4,4))
ax.set_aspect('equal')
ax.axis('off')

# basis vectors of hexagonal lattice
a1 = np.array([1, 0])
a2 = np.array([0.5, np.sqrt(3)/2])
M = 8  # box side in lattice units
for n1 in range(-M, M+1):
    for n2 in range(-M, M+1):
        center = n1*a1 + n2*a2
        hex = RegularPolygon(center, 6, radius=0.4, orientation=0,
                             facecolor='white', edgecolor='black', lw=1.5)
        ax.add_patch(hex)
ax.set_xlim(-M-0.5, M+0.5)
ax.set_ylim(-M-0.5, M+0.5)
ax.set_title('k-space substrate (bubble lattice)', fontsize=10)
plt.tight_layout()
plt.savefig('hexagonal_lattice.png', dpi=300, bbox_inches='tight')
plt.close()

