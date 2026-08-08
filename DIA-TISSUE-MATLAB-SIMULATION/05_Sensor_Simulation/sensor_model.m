function [measured_acc,info] = sensor_model(true_acc,params)
% DIA-TISSUE ADXL355-LIKE SENSOR MODEL
range_limit = params.range_g*9.80665;
noise_rms = params.noise_density*sqrt(params.bandwidth);
noise = noise_rms.*randn(size(true_acc));
biased_acc = true_acc+params.bias;
noisy_acc = biased_acc+noise;
saturated_acc = min(max(noisy_acc,-range_limit),range_limit);
quantization_step = (2*range_limit)/(2^params.bits);
measured_acc = round(saturated_acc/quantization_step)*quantization_step;
info.noise_rms = noise_rms;
info.range_limit = range_limit;
info.quantization_step = quantization_step;
end