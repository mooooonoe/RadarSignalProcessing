%% Reshape Data
function [frameComplex_cell] = ReshapeData(NChirp, NChan, NSample, Nframe, adcRawData)
%% data load and type casting
% adcRawData -> adc_raw_data1
frameComplex_cell = cell(1,Nframe);

for frames = 1:Nframe
adc_raw_data1 = adcRawData.data{frames};

% adc_raw_data1->uint type 이기때문에 double type으로 바꿔줘야 연산 가능
adc_raw_data = cast(adc_raw_data1,"double");
% unsigned => signed
signed_adc_raw_data = adc_raw_data - 65536 * (adc_raw_data > 32767);

%% data reshaping
% pre allocation
frameComplex = zeros(NChirp, NChan, NSample);

% IIQQ data
re_adc_raw_data4=reshape(signed_adc_raw_data,[4,length(signed_adc_raw_data)/4]);
rawDataI = reshape(re_adc_raw_data4(1:2,:), [], 1);
rawDataQ = reshape(re_adc_raw_data4(3:4,:), [], 1);

frameData = [rawDataI, rawDataQ];
frameCplx = frameData(:,1) + 1i*frameData(:,2);

% IIQQ->IQ smaple->channel->chirp
temp = reshape(frameCplx, [NSample * NChan, NChirp]).';
for chirp=1:NChirp                            
    frameComplex(chirp,:,:) = reshape(temp(chirp,:), [NSample, NChan]).';
end 
frameComplex_cell{frames} = frameComplex;
end