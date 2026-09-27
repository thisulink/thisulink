function [X1, X2, N] = fourier_pair(t, u1, u2, f, t_skip)
% FOURIER_PAIR  Complex amplitude of two signals at frequency f.
%
%   [X1, X2, N] = fourier_pair(t, u1, u2, f, t_skip)
%
% Uses the samples with t >= t_skip, truncated to an integer number of
% periods of f (no window needed for a coherent single-tone estimate).
% |X| is the peak amplitude of the tone; angle(X1*conj(X2)) is the phase by
% which u2 lags u1, wrapped to (-pi, pi]. N is the number of samples used.

t  = t(:);
u1 = u1(:);
u2 = u2(:);
idx = find(t >= t_skip);
dt = t(2) - t(1);
nPeriods = floor((t(end) - t(idx(1)) + dt) * f);
if nPeriods < 1
    error('fourier_pair: window shorter than one period of %.1f Hz', f);
end
N = round(nPeriods / (f * dt));
N = min(N, numel(idx));
idx = idx(1:N);

e  = exp(-1i * 2 * pi * f * t(idx));
X1 = 2 / N * sum((u1(idx) - mean(u1(idx))) .* e);
X2 = 2 / N * sum((u2(idx) - mean(u2(idx))) .* e);
end
