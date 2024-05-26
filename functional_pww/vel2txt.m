% Specify the file name for the output .txt file
output_filename = 'frameComplex.txt';

% Open the file for writing
fileID = fopen(output_filename, 'w');

% Check if the file was opened successfully
if fileID == -1
    error('Cannot open file for writing.');
end

% Write the data to the file
for i = 1:size(frameComplex, 1)
    for j = 1:size(frameComplex, 2)
        realPart = real(frameComplex(i, j))/100; % 실수 부분을 밀리 단위로 변환
        imagPart = imag(frameComplex(i, j))/100; % 허수 부분을 밀리 단위로 변환
        % Write the complex number in the format: realPart<TAB>imagPart<TAB>
        % The '\t' character is used for the tab separation.
        fprintf(fileID, '%.4f+%.4f\t', realPart, imagPart);
    end
    % After writing one row of complex numbers, add a newline
    fprintf(fileID, '\n');
end

% Close the file
fclose(fileID);

disp(['Complex frame data written to ', output_filename]);
