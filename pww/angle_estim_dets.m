%% Angle estimation for each peak in detout
function [Resel_agl, vel_ambg_list, rng_excd_list] = angle_estim_dets(objOut, frame_number, ...
    radarCubeData, NChirp, angleFFTSize, Rx, Tx, num_crop)

% objOut: Doppler, Range, cellPower 순서
detout = objOut;
% Velocity_FFT: channel, Range, Doppler 순서
Velocity_FFT = permute(radarCubeData{frame_number},[2,3,1]);

Resel_agl = [];
vel_ambg_list = [];
rng_excd_list = [];
fft_Rang = size(Velocity_FFT, 2);

for ai = 1:size(detout, 2)

    rx_vect = squeeze(Velocity_FFT(:, detout(2,ai), detout(1,ai)));

    % Phase Compensation on the range-velocity bin for virtual elements
    pha_comp_term = exp(-1i * (pi * (detout(1,ai) - NChirp/2 - 1) / NChirp));
    rx_vect(Rx+1:Rx*Tx) = rx_vect(Rx+1:Rx*Tx) * pha_comp_term;

    % Estimate Angle on set1
    % 각 angle FFT된 data에서 peak를 찾음.
    Angle_FFT1 = fftshift(fft(rx_vect, angleFFTSize));
    [MM,II] = max(abs(Angle_FFT1));
    Resel_agl = [Resel_agl, II];

    % Velocity disambiguation on set2 -- flip the sign of the symbols 
    % corresponding to Tx2
    rx_vect(Rx+1:Rx*Tx) = - rx_vect(Rx+1:Rx*Tx);
    Angle_FFT1_flip = fftshift(fft(rx_vect, angleFFTSize));
    [MM_flip,II_flip] = max(abs(Angle_FFT1_flip));

    if MM_flip > 1.2 * MM
        % now has velocity ambiguration, need to be corrected 
        vel_ambg_list = [vel_ambg_list, ai];
    end
    
%     물체가 특정 범위를 벗어나는 경우에 대한 처리
    if detout(2,ai) <= num_crop || detout(2,ai) > fft_Rang - num_crop
        rng_excd_list = [rng_excd_list, ai];
    end
end
