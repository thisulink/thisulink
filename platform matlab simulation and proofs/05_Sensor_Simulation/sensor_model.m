function [measured_acc, info] = sensor_model(true_acc, params)
% THISULINK ANALOG DEVICES ADXL355 ACCELEROMETER SENSOR MODEL
% High-precision 20-bit digital triaxial accelerometer emulation.
%
% Inputs:
%   true_acc - Ground truth physical acceleration vector [m/s^2]
%   params   - Struct containing sensor hardware parameters:
%              .range_g        - Measurement range [+/- g] (e.g. 2.048)
%              .bits           - ADC resolution [bits] (20)
%              .bandwidth      - Internal digital filter cut-off [Hz] (150)
%              .noise_density  - Noise spectral density [m/s^2/sqrt(Hz)]
%              .bias           - Sensor DC offset bias [m/s^2]
%
% Outputs:
%   measured_acc - Simulated digitized output [m/s^2]
%   info         - Struct containing noise RMS, quantization step, and saturation stats

g = 9.80665;
range_limit = params.range_g * g;

% Accelerometer internal Gaussian thermal & flicker noise
noise_rms = params.noise_density * sqrt(params.bandwidth);
noise = noise_rms .* randn(size(true_acc));

% Biased and noise-corrupted physical signal
noisy_acc = true_acc + params.bias + noise;

% Dynamic range saturation
saturated_acc = min(max(noisy_acc, -range_limit), range_limit);

% 20-bit digital ADC quantization
quantization_step = (2 * range_limit) / (2^params.bits);
measured_acc = round(saturated_acc / quantization_step) * quantization_step;

% Diagnostic metadata
info.noise_rms = noise_rms;
info.range_limit = range_limit;
info.quantization_step = quantization_step;
info.quantization_step_ug = (quantization_step / g) * 1e6;
info.num_saturated = sum(abs(noisy_acc) >= range_limit);
end
