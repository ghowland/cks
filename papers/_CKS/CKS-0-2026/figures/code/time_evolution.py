import matplotlib.pyplot as plt
import numpy as np
from kspace import KSpaceSubstrate
import mpmath as mp

# Dark energy & coupling vs cosmic age
t_vals = np.logspace(10, 18, 100)  # age in seconds
N_vals = 3e8 * t_vals / 1.616e-35   # N(t) = ct/l_P
beta_vals = []
rho_Lambda_vals = []
for t, N in zip(t_vals, N_vals):
    sub = KSpaceSubstrate(N=str(int(N)))
    beta = sub.beta()  # β(N) = β_P / N
    rho_L = 1 / N        # ρΛ = 1/N
    beta_vals.append(float(beta))
    rho_Lambda_vals.append(float(rho_L))

fig, ax1 = plt.subplots(figsize=(5,3.5))
ax2 = ax1.twinx()
ax1.loglog(t_vals, beta_vals, color='navy', lw=2.5, label='β(t) = β_P / N(t)')
ax2.loglog(t_vals, rho_Lambda_vals, color='firebrick', lw=2.5, label='ρΛ(t) = 1/N(t)')
ax1.set_xlabel('Cosmic age t (s)')
ax1.set_ylabel('Substrate stiffness β', color='navy')
ax2.set_ylabel('Dark energy density', color='firebrick')
ax1.grid(True, which="both", ls="--", alpha=0.3)
plt.tight_layout()
plt.savefig('time_evolution.png', dpi=300, bbox_inches='tight')
plt.close()

