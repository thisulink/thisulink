function z = det_randn(seed, varargin)
% DET_RANDN  Deterministic standard-normal random numbers (MATLAB + Octave).
%
%   z = det_randn(seed, n)        -> n x 1 column vector
%   z = det_randn(seed, r, c)     -> r x c matrix
%   z = det_randn(seed, [r c])    -> r x c matrix
%
% MATLAB's rng() and GNU Octave's rand/randn use different generators, so
% the same seed gives different numbers on the two platforms. All synthetic
% noise and cohort data in this suite is drawn from this function instead,
% so the printed numbers (and the numbers quoted in the READMEs) are the
% same on MATLAB and on Octave.
%
% Method: Park-Miller "minimal standard" LCG (a = 16807, m = 2^31 - 1),
% evaluated in exact double-precision integer arithmetic, run as a set of
% parallel streams (for speed), followed by the Box-Muller transform.
% Good enough for simulation noise; NOT a cryptographic or research-grade RNG.

if nargin < 2
    sz = [1 1];
elseif nargin == 2
    sz = varargin{1};
    if isscalar(sz)
        sz = [sz 1];
    end
else
    sz = [varargin{1} varargin{2}];
end
n = prod(sz);
if n == 0
    z = zeros(sz);
    return;
end

M  = 2147483647;   % 2^31 - 1
A  = 16807;        % LCG multiplier
AS = 48271;        % multiplier used only to seed the parallel streams

nu = 2 * ceil(n / 2);            % Box-Muller consumes uniforms in pairs
S  = max(1, ceil(sqrt(nu)));     % number of parallel streams
L  = ceil(nu / S);               % steps per stream

% Seed streams
x = zeros(S, 1);
s = mod(floor(abs(double(seed))), M - 1) + 1;
for j = 1:S
    s = mod(AS * s, M);
    x(j) = s;
end
% Discard a few initial values of every stream
for k = 1:4
    x = mod(A * x, M);
end

U = zeros(S, L);
for k = 1:L
    x = mod(A * x, M);
    U(:, k) = x / M;             % uniform in (0, 1), never exactly 0 or 1
end
U = U(:);
U = U(1:nu);

u1 = U(1:2:end);
u2 = U(2:2:end);
r  = sqrt(-2 * log(u1));
zz = [r .* cos(2 * pi * u2), r .* sin(2 * pi * u2)]';
zz = zz(:);
z  = reshape(zz(1:n), sz);
end
