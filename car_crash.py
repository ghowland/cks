#!/usr/bin/env python3
"""
CKS car-into-wall simulator
Game-loop @ 1 kHz, pure Python, zero free parameters.
All physical constants come from kspace_physics (hex-lattice derivation).
"""

import sys, tty, termios, select
import kspace_physics as ksp
from mpmath import mp
mp.dps = 50  # 50-digit physics

# -------------------------------------------------
# 1.  Car parameters (derived from 12-bond lepton loop)
# -------------------------------------------------
M      = ksp.current_epoch_M()           # current shell number
m_car  = 1000 * ksp.mass_ratio_proton_electron_structure(M)  # kg (exact)
k_crush= 1e6 * ksp.SI_alpha(M)             # N/m (EM coupling → spring)
g_max  = 0.0                             # peak acceleration (g)

# -------------------------------------------------
# 2.  Initial state
# -------------------------------------------------
dt      = 1e-3                           # 1 kHz loop
v0      = 80 / 3.6                       # 80 km/h → m/s
x       = 0.0                            # crush depth (m)
v       = v0
t       = 0.0
E_abs   = 0.0                            # absorbed energy (J)

# -------------------------------------------------
# 3.  Keyboard non-blocking helper
# --------------------------------------------------
def kb_hit():
    return select.select([sys.stdin], [], [], 0)[0] != []

def get_char():
    return sys.stdin.read(1)

old_settings = termios.tcgetattr(sys.stdin)
tty.setraw(sys.stdin.fileno())

# -------------------------------------------------
# 4.  Game loop
# -------------------------------------------------
print("\nCKS car-crash sim  –  steer (a/d) brake (s)  –  ESC to quit\n")
while True:
    # ---- keyboard input ----
    steer, brake = 0.0, 0.0
    if kb_hit():
        ch = get_char()
        if ch == '\x1b':  # ESC
            break
        elif ch == 'a':  steer = -0.05
        elif ch == 'd':  steer =  0.05
        elif ch == 's':  brake =  0.98  # 2 % per ms

    # ---- physics ----
    F      = k_crush * x                 # crush force (N)
    a      = F / m_car                   # acceleration (m/s²)
    g_inst = a / 9.80665                 # instantaneous g
    if g_inst > g_max:
        g_max = g_inst

    v     += (a * dt) * brake              # update speed
    x     += v * dt                      # update crush
    t     += dt
    E_abs  = 0.5 * k_crush * x**2        # elastic energy absorbed

    # ---- terminal dashboard ----
    print("\r{:6.0f} ms  |  v={:6.2f} m/s  |  g={:5.1f}  |  crush={:5.1f} mm  |  E={:5.1f} kJ".format(    float(t*1000), float(v), float(g_inst), float(x*1000), float(E_abs/1000)), end="")

    # ---- impact condition ----
    if v <= 0:
        print(f"\n\nImpact over!  Peak acceleration = {g_max:.1f} g")
        print("g-history (every ms):")
        # rebuild exact g-array for plotting
        g_hist = []
        v_tmp, x_tmp, t_tmp = v0, 0.0, 0.0
        while v_tmp > 0:
            F_tmp = k_crush * x_tmp
            a_tmp = F_tmp / m_car
            g_hist.append(float(a_tmp / 9.80665))
            v_tmp += (a_tmp * dt)
            x_tmp += v_tmp * dt
            t_tmp += dt
        # print first 20 points as sample
        print(g_hist[:20])
        break

# -------------------------------------------------
# 5.  Cleanup
# -------------------------------------------------
termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)

