import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import RegularPolygon, Polygon

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(6,3), sharex=True, sharey=True)
for ax in (ax1, ax2):
    ax.set_aspect('equal')
    ax.axis('off')

# --- 6-bond vortex (photon, gluon, boson) ---
hex1 = RegularPolygon((0,0), 6, radius=0.5, orientation=0,
                      facecolor='lightblue', edgecolor='black', lw=2)
ax1.add_patch(hex1)
# draw the 6 bonds
for i in range(6):
    x = 0.5 * np.cos(i * np.pi / 3)
    y = 0.5 * np.sin(i * np.pi / 3)
    ax1.plot([0, x], [0, y], 'k', lw=2)
ax1.set_xlim(-0.7, 0.7)
ax1.set_ylim(-0.7, 0.7)
ax1.set_title('6-bond vortex\n(photon, gluon, boson)', fontsize=9)

# --- 12-bond vortex (electron, muon, fermion) ---
hex2 = RegularPolygon((0,0), 6, radius=0.5, orientation=0,
                      facecolor='lightcoral', edgecolor='black', lw=2)
ax2.add_patch(hex2)
# draw 12 bonds (double-hexagon)
for i in range(12):
    r = 0.5 if i % 2 == 0 else 0.25
    x = r * np.cos(i * np.pi / 6)
    y = r * np.sin(i * np.pi / 6)
    ax2.plot([0, x], [0, y], 'k', lw=2)
ax2.set_xlim(-0.7, 0.7)
ax2.set_ylim(-0.7, 0.7)
ax2.set_title('12-bond vortex\n(electron, muon, fermion)', fontsize=9)

plt.tight_layout()
plt.savefig('bond_topology.png', dpi=300, bbox_inches='tight')
plt.close()

