% 저장할 비디오 파일명 및 설정
outputVideo = VideoWriter('outputVideo.avi'); % 저장할 파일명과 확장자 지정
outputVideo.FrameRate = 30; % 초당 프레임 수 (30으로 설정하였으나 필요에 따라 조절 가능)

% 비디오를 저장할 준비
open(outputVideo);

% 저장할 행렬 데이터 (예시로 랜덤 데이터 생성)
numFrames = 100; % 저장할 프레임 수
frameSize = [200, 300]; % 프레임 크기 (가로 x 세로)
for frame = 1:numFrames
    % 행렬 데이터 생성 (예시로 랜덤 데이터 생성)
    matrixData = rand(frameSize);
    
    % 이미지로 변환
    frameImage = uint8(255 * matrixData); % 데이터를 0에서 255 사이의 값으로 변환
    
    % 비디오에 프레임 추가
    writeVideo(outputVideo, frameImage);
end

% 비디오 저장 종료
close(outputVideo);
