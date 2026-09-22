function [f, magnitude] = fft_analysis(signal, fs)
% THISULINK COHERENT GAIN HANN-WINDOWED FFT ANALYSIS
% Accurately reconstructs single-sided amplitude spectrum without spectral leakage.
%
% Inputs:
%   signal - Time-domain measurement vector
%   fs     - Sampling frequency [Hz]
%
% Outputs:
%   f         - Frequency axis vector [Hz]
%   magnitude - Single-sided peak amplitude spectrum [units of signal]

signal = signal(:);
N = length(signal);

% Detrend / remove DC baseline
signal_ac = signal - mean(signal);

% Apply Hann window to eliminate spectral leakage
w = hann(N);
windowed_signal = signal_ac .* w;

% Coherent gain factor of Hann window
coherent_gain = sum(w) / N;

% Compute FFT and normalize
Y = fft(windowed_signal);
P2 = abs(Y) / (N * coherent_gain);

% Single-sided spectrum
if rem(N, 2) == 0
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2 * P1(2:end-1);
else
    P1 = P2(1:(N+1)/2);
    P1(2:end) = 2 * P1(2:end);
end

magnitude = P1;
f = (0:length(P1)-1)' * (fs / N);
end
