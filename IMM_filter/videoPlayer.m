clc; clear; close all;
% videoFilePath = 'human_eight.mp4';
% 
% videoReader = VideoReader(videoFilePath);
% 
% figure;
% 
% while hasFrame(videoReader)
%     frame = readFrame(videoReader); 
%     imshow(frame);
%     pause(1/(3 * videoReader.FrameRate));
% end

% videoFilePath = 'human_eight.mp4';
% videoReader = VideoReader(videoFilePath);
% figure;
% 
% speedUpFactor = 5;
% 
% while hasFrame(videoReader)
%     for i = 1:speedUpFactor-1
%         if hasFrame(videoReader)
%             readFrame(videoReader); 
%         end
%     end
%     if hasFrame(videoReader)
%         frame = readFrame(videoReader); 
%         imshow(frame); 
%         pause(1/(speedUpFactor * videoReader.FrameRate)); 
%     end
% end


function main()
    % 비디오 파일 경로
    videoFilePath = 'human_eight.mp4';

    % 속도 증가 비율 설정 (예: 10배 빠르게)
    speedUpFactor = 10;

    % 병렬 풀 열기
    pool = gcp(); % 병렬 풀 열기

    % 비디오 재생 비동기 실행
    f = parfeval(@playVideo, 0, videoFilePath, speedUpFactor);

    % updatePlot 함수 실행
    updatePlot();

    % 비디오 재생이 끝날 때까지 대기 (선택 사항)
    wait(f);

    % 병렬 풀 닫기
    delete(pool);
end

function playVideo(videoFilePath, speedUpFactor)
    videoReader = VideoReader(videoFilePath);

    figure;
    
    while hasFrame(videoReader)
        for i = 1:speedUpFactor-1
            if hasFrame(videoReader)
                readFrame(videoReader); % 프레임 건너뛰기
            end
        end
        if hasFrame(videoReader)
            frame = readFrame(videoReader); % 프레임 읽기
            imshow(frame); % 피규어에 프레임 표시
            pause(1/(speedUpFactor * videoReader.FrameRate)); % 프레임 속도에 맞추어 일시 정지
        end
    end
end

function updatePlot()
    % 예제 updatePlot 함수
    figure;
    for k = 1:100
        plot(rand(1,10));
        pause(0.1); % 간단한 일시 정지
    end
end

% 메인 함수 호출
main();
