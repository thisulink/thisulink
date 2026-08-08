function [f,magnitude] = fft_analysis(signal,fs)
% DIA-TISSUE FFT Analysis
signal = signal(:);
N = length(signal);
signal = signal-mean(signal);
w = hann(N);
windowed_signal = signal.*w;
Y = fft(windowed_signal);
coherent_gain = sum(w)/N;
P2 = abs(Y)/(N*coherent_gain);
if rem(N,2) == 0
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
else
    P1 = P2(1:(N+1)/2);
    P1(2:end) = 2*P1(2:end);
end
magnitude = P1;
f = (0:length(P1)-1)'*(fs/N);
end