%% Angle FFT (Azimuth) 기존 Range Azimuth FFT 코드와 결과는 거의 비슷함
% input: RangeFFT된 data
function[AngData,AngData_mti, ram_output2, ram_output2_mti] = AngleFFT(NChirp, ...
    NChan, NSample, angleFFTSize, frame_number, radarCubeData_cell, radarCubeData_mti_cell)

% preallocation
AngData = zeros(NChirp, angleFFTSize, NSample);
AngData_mti = zeros(NChirp, angleFFTSize, NSample);

% Angle FFT
    % not MTI
  for j = 1:NSample
      for i = 1:NChirp
         % 1x4 벡터를 4x1 벡터로 reshape하고 taylor window 적용
         Rxvector = reshape(radarCubeData_cell{frame_number}(i,:,j),NChan,[]).*taylorwin(NChan);
         % angle FFT
         AngData(i,:,j) = fftshift(fft(Rxvector,angleFFTSize));
      end
  end
   % MTI
   for j = 1:NSample
      for i = 1:NChirp
         % 1x4 벡터를 4x1 벡터로 reshape하고 taylor window 적용
         Rxvector_mti = reshape(radarCubeData_mti_cell{frame_number}(i,:,j),NChan,[]).*taylorwin(NChan);
         % angle FFT
         AngData_mti(i,:,j) = fftshift(fft(Rxvector_mti,angleFFTSize));
      end
   end
 % plot 하기 위한 data
 ram_output2 = squeeze(sum(abs(AngData(:,:,:)),1));
 ram_output2_mti = squeeze(sum(abs(AngData_mti(:,:,:)),1));
 
 ram_output2 = ram_output2';
 ram_output2_mti = ram_output2_mti';
 
%% 깃허브 참고한 거
% permute하는 이유 ram_output에서 플랏할 때 transpose안할 수 있음
% Xcube = permute(radarCubeData_mti_cell{frame_number},[3,2,1]);
% NChan = 4;
% Is_Windowed = 1;
% for i = 1:NChirp
%     for j = 1:NSample
%         if Is_Windowed
%             win_xcube = reshape(Xcube(j,:,i),NChan,[]).*taylorwin(Ne);
%         else
%             win_xcube = reshape(Xcube(j,:,i),NChan,[]).*1;
%         end
%         AngData(j,:,i) = fftshift(fft(win_xcube,angleFFTSize));
%     end
% end
% ram_output2 = squeeze(sum(abs(AngData(:,:,:)),3));
% nexttile;
% imagesc(angleBin,rangeBin,ram_output2)
% xlabel('Angle( \circ)')
% ylabel('Range(m)')
% colorbar;
% axis xy