const std = @import("std");
const math = std.math;

pub const Physics = struct {
    N: f64, // Bubble count.  The 1 constant in the universe

    pub fn alpha_em_inv(self: Physics) f64 {
        const ln_n = @log(self.N);
        const n_third = math.pow(f64, self.N, 1.0 / 3.0);
        return (math.e * 3.0 * n_third) / (2.0 * math.pi * ln_n);
    }

    pub fn alpha_g(self: Physics) f64 {
        return 1.0 / self.N;
    }

    pub fn holographic_scale(self: Physics) f64 {
        return math.pow(f64, self.N, 2.0 / 3.0) / 1e40;
    }

    pub fn coupling_strength(self: Physics) f64 {
        return 1.0 / self.N * 1e40; // Scaled for simulation
    }

    pub fn gravity_scale(self: Physics) f64 {
        return self.alpha_g() * 100.0; // Scaled for gameplay
    }

    pub fn mass_electron(self: Physics) f64 {
        _ = self;
        return 1.0;
    }

    pub fn mass_muon(self: Physics) f64 {
        const ln_n = @log(self.N);
        const n_third = math.pow(f64, self.N, 1.0 / 3.0);
        const M = @sqrt(self.N / 3.0);
        const lambda = (M * ln_n * math.e) / (12.0 * math.pi);
        return @sqrt(lambda / (2.0 * math.pi)) / n_third * ln_n;
    }

    pub fn dark_energy(self: Physics) f64 {
        return 1.0 / self.N;
    }
};
