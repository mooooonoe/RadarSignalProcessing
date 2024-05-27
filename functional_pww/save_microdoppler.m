%% micro doppler image를 원하는 디렉터리에 저장

% ****중요*****
% 작업공간에서 필요한 데이터를 가져와 쓰기 때문에 visualizer를 항상 먼저 실행하고 해야함.
% 따라서 clc,keyboard, clear등 작업공간 영향 주는 거 사용 X

% Object의 종류를 고른다.
choice_object = input('Select an option:\n1. Drone\n2. People\n3. Cycle\nchoice: ');

% 저장할 range의 시작과 끝을 고른다.
first_range = input('\nSelect first range IDX:\n');
last_range = input('\nSelect last range IDX:\n');

% 선택한 옵션에 따라 파일 경로 설정
switch choice_object
    case 1
        filepath = 'C:\\Users\\dnjsd\\matlab_plot\\drone\\';
    case 2
        filepath = 'C:\\Users\\dnjsd\\matlab_plot\\people\\';
    case 3
        filepath = 'C:\\Users\\dnjsd\\matlab_plot\\cycle\\';
    otherwise
        error('Invalid choice. Please select 1, 2, or 3.');
end

% 설정한 range의 범위만큼 jpg 로 저장
for save_RangeBinIdx = first_range:last_range
    % Micro doppler
    [save_time_axis, save_micro_doppler]  = microdoppler(NChirp, NChan, Nframe, RangeBinIdx, input_microDoppler);
    % power of microdoppler
    sdb = squeeze(10*log10((abs(save_micro_doppler(:, chanIdx, :)))));

    % plot
    fig = imagesc(save_time_axis, velocityAxis, sdb);
    filename = sprintf('%smicrdoppler_%d.jpg', filepath, save_RangeBinIdx);
    saveas(fig, filename);
end