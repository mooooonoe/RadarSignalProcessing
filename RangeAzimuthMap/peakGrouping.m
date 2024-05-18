function [objOut] = peakGrouping(detected_points_2D, db_doppler)

% 2D CFAR에서 detecting된 target의 Range, Doppler 인덱스 구하기
% detected_points_2D row: range, column: doppler
[row_2d, col_2d] = find(detected_points_2D ~= 0);

% preallocation
cellPower = zeros(size(row_2d));
objOut = [];

% detecting된 target의 cell power 구하기
for i = 1:size(row_2d)
    cellPower(i) = db_doppler(row_2d(i), col_2d(i));
end
% 입력 detMat 구하기 
% 해당 코드에서 1행이 Doppler이고 2행이 Range이기 때문에 col, row 위치 바꿔서 저장
detMat = [col_2d'; row_2d'; cellPower'];
numDetectedObjects = size(detMat,2);

% detMat을 cellPower가 큰 순서부터 내림차순으로 정리
[~, order] = sort(detMat(3,:), 'descend');
detMat = detMat(:,order);

for ni = 1:numDetectedObjects
    detectedObjFlag = 1;
    rangeIdx = detMat(2,ni);
    dopplerIdx = detMat(1,ni);
    peakVal = detMat(3,ni);
    kernel = zeros(3,3);
    
    %% fill the middle column of the kernel
    % CUT라고 보면 됨. 검출할 객체
    kernel(2,2) = peakVal;
    
    % kernel을 만드는 과정
    % detMat에서 range,doppler 인덱스가 1씩 차이나는 것들을 모은다.
    % 설명은 캡스톤 진행사항 word에있음
    
    % fill the middle column of the kernel
    need_index = find(detMat(1,:) == dopplerIdx & detMat(2,:) == rangeIdx+1);
    if ~isempty(need_index)
        kernel(1,2) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx & detMat(2,:) == rangeIdx-1);
    if ~isempty(need_index)
        kernel(3,2) = detMat(3,need_index(1));
    end

    % fill the left column of the kernel
    need_index = find(detMat(1,:) == dopplerIdx-1 & detMat(2,:) == rangeIdx+1);
    if ~isempty(need_index)
        kernel(1,1) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx-1 & detMat(2,:) == rangeIdx);
    if ~isempty(need_index)
        kernel(2,1) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx-1 & detMat(2,:) == rangeIdx-1);
    if ~isempty(need_index)
        kernel(3,1) = detMat(3,need_index(1));
    end
    
    % Fill the right column of the kernel
    need_index = find(detMat(1,:) == dopplerIdx+1 & detMat(2,:) == rangeIdx+1);
    if ~isempty(need_index)
        kernel(1,3) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx+1 & detMat(2,:) == rangeIdx);
    if ~isempty(need_index)
        kernel(2,3) = detMat(3,need_index(1));
    end
    
    need_index = find(detMat(1,:) == dopplerIdx+1 & detMat(2,:) == rangeIdx-1);
    if ~isempty(need_index)
        kernel(3,3) = detMat(3,need_index(1));
    end
    
    % Compare the detected object to its neighbors.Detected object is
    % at index [2,2]
    if kernel(2,2) ~= max(max(kernel))
        detectedObjFlag = 0;
    end
    
    if detectedObjFlag == 1
        objOut = [objOut, detMat(:,ni)];
    end
end