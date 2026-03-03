import numpy as np
from scipy.io import wavfile

# pip install numpy scipy sounddevice

try:
    import sounddevice as sd
    HAS_SOUND = True
except ImportError:
    HAS_SOUND = False

def generate_e_lum_heartbeat(duration_sec=5, sample_rate=44100):
    """
    Synthesizes the E-LUM Heartbeat based on CKS-MATH-116-2026.
    Phases: 
    E   : Initiation (Sub-Bass)
    ... : Expansion (Rising Harmonics)
    LU  : Impact (Metallic Mid-Range)
    -M  : Settlement (Low-Freq Thud)
    """
    t_cycle = np.linspace(0, 1, sample_rate, endpoint=False)
    full_audio = np.array([])

    for _ in range(duration_sec):
        # Initialize silence for the 1s cycle
        cycle = np.zeros(sample_rate)

        # --- I. INITIATION: "E" (Attack, 0-150ms) ---
        # Sub-bass 32Hz sine with a sharp exponential attack
        t_e = t_cycle[0:int(0.150 * sample_rate)]
        e_wave = np.sin(2 * np.pi * 32 * t_e)
        e_env = np.exp(-t_e * 20) * (1 - np.exp(-t_e * 100))
        cycle[0:len(e_wave)] += e_wave * e_env * 0.8

        # --- II. EXPANSION: "The Bloom" (Sustain, 150-450ms) ---
        # Rising harmonic hum (64Hz to 128Hz)
        t_sustain = t_cycle[int(0.150 * sample_rate):int(0.450 * sample_rate)]
        freq_rise = np.linspace(64, 128, len(t_sustain))
        s_wave = np.sin(2 * np.pi * freq_rise * t_sustain)
        s_env = 0.2 * np.sin(np.pi * (t_sustain - 0.150) / 0.300)
        cycle[int(0.150 * sample_rate):int(0.450 * sample_rate)] += s_wave * s_env

        # --- III. IMPACT: "LU-" (Decay/Peak, 450-550ms) ---
        # Metallic clashing frequency (Complex 440Hz + 880Hz + 1200Hz)
        t_lu = t_cycle[int(0.450 * sample_rate):int(0.550 * sample_rate)]
        lu_wave = (np.sin(2 * np.pi * 440 * t_lu) + 
                   0.5 * np.sin(2 * np.pi * 880 * t_lu) + 
                   0.2 * np.sin(2 * np.pi * 1200 * t_lu))
        lu_env = np.exp(-(t_lu - 0.450) * 40)
        cycle[int(0.450 * sample_rate):int(0.550 * sample_rate)] += lu_wave * lu_env * 0.6

        # --- IV. SETTLEMENT: "-M" (Resolve, 550-750ms) ---
        # Low frequency thud (40Hz) for Logismos locking
        t_m = t_cycle[int(0.550 * sample_rate):int(0.750 * sample_rate)]
        m_wave = np.sin(2 * np.pi * 40 * t_m)
        m_env = np.exp(-(t_m - 0.550) * 10)
        cycle[int(0.550 * sample_rate):int(0.750 * sample_rate)] += m_wave * m_env * 0.9

        # Append cycle to full audio
        full_audio = np.concatenate([full_audio, cycle])

    # Normalize to prevent clipping
    full_audio = full_audio / np.max(np.abs(full_audio))
    return full_audio

if __name__ == "__main__":
    print("Generating CKS Heartbeat: E-LUM...")
    audio_data = generate_e_lum_heartbeat(duration_sec=10)

    # Save to file
    filename = "cks_heartbeat_elum.wav"
    wavfile.write(filename, 44100, (audio_data * 32767).astype(np.int16))
    print(f"Waveform saved to {filename}")

    # Play sound if sounddevice is available
    if HAS_SOUND:
        print("Playing 'E-LUM, E-LUM, E-LUM' (1Hz Macro-Sync)...")
        sd.play(audio_data, 44100)
        sd.wait()
    else:
        print("Install 'sounddevice' to play audio directly.")
    
    print("Axioms first. Axioms always. Q.E.D.")

