% Plot part
close all;
MTIfiltering = 1;
log_plot = 0;
dbscan_mode = 1;
%% Time domain output plot
% plot time domain
figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);
nexttile;
plot(t,currChDataI(:),t,currChDataQ(:))
xlabel('time (seconds)');                  
ylabel('ADC time domain output');        
title('Time Domain Output');
grid on;

%% FFT Range Profile plot
% plot range profile MTI or not MTI
nexttile;
if MTIfiltering
    % plot MTI filter range profile 
    plot(rangeBin,channelData_mti)
    xlabel('Range (m)');                  
    ylabel('Range FFT output (dB)');        
    title('Range Profile (MTI)');
    grid on;
else
    % plot not MTI filter range profile
    plot(rangeBin,channelData)
    xlabel('Range (m)');                  
    ylabel('Range FFT output (dB)');        
    title('Range Profile (not MTI)');
    grid on;
end

%% Range Doppler FFT plot - RDM
% plot Range Doppler Map
nexttile;
if MTIfiltering
    imagesc(velocityAxis,rangeBin,db_doppler_mti);
    title('Range-Doppler Map (MTI)');
else
    imagesc(velocityAxis,rangeBin,db_doppler);
    title('Range-Doppler Map (not MTI)');
end
xlabel('Velocity (m/s)');
ylabel('Range (m)');
% yticks(0:2:max(rangeBin));
colorbar;
axis xy

%% Range Azimuth FFT Plot - RAM
% plot RAM
figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);
nexttile;
if MTIfiltering
    imagesc(angleBin,rangeBin,ram_output_mti)
    title('Range Azimuth map MTI');
else
    imagesc(angleBin,rangeBin,ram_output)
    title('Range Azimuth map not MTI');
end
xlabel('Angle( \circ)')
ylabel('Range(m)')
yticks(0:2:max(rangeBin));
colorbar;
axis xy

%% Range Azimuth FFT plot - Cartesian Plane
% plot Cartesian Plane
nexttile;
% MTI
if MTIfiltering
   if log_plot
     surf(y_axis, x_axis, (mag_data_mti).^0.4,'EdgeColor','none');
   else
     surf(y_axis, x_axis, abs(mag_data_mti),'EdgeColor','none');
   end
     title('Range Azimuth FFT - Cartesian Plane (MTI)');
% not MTI
else
   if log_plot
     surf(y_axis, x_axis, (mag_data).^0.4,'EdgeColor','none');
   else
     surf(y_axis, x_axis, abs(mag_data),'EdgeColor','none');
   end
    title('Range Azimuth FFT - Cartesian Plane (not MTI)');
end
view(2);
colorbar;
xlabel('meters');
ylabel('meters');
% 
%  %% Find Target plot
% % plot peaks and targets
% nexttile;
% plot(rangeBin, channelData_mti); 
% hold on;
% plot(rangeBin(peak_locs), peaks, 'ro');
% hold on;
% title('Find Target');
% xlabel('Range (m)');
% ylabel('Power (dB)');
% % rangeBin 중에서 peak 중에서 target의 Index
% plot(rangeBin(peak_locs(target_Idx)),target,'go','Markersize',8);
% 
% variance = var(channelData_mti);
% 
% %% 1D CA-CFAR plot
% % Range FFT data plot
% nexttile;
% plot(rangeBin, cfarData_mti, 'LineWidth', 0.5);
% hold on;
% 
% % Threshold plot
% plot(rangeBin, th, 'r', 'LineWidth', 0.5);
% legend('Range Profile', 'CFAR threshold');
% hold on;
% 
% % detected points plot
% plot(rangeBin(detected_points_1D), (cfarData_mti(detected_points_1D)),'ro','MarkerSize', 8);
% legend('Range Profile', 'CFAR Threshold', 'Detected Points');
% xlabel('Range (m)');
% ylabel('power (dB)');
% title('CFAR Detection');
% 
% %% 2D RDM CA-OS CFAR plot
% % plot 2D CAOS-CFAR
% figure('Position', [300,100, 1200, 800]);
% tiledlayout(2,2);
% nexttile;
% if MTIfiltering
%     imagesc(velocityAxis,rangeBin,detected_points_2D);
%     title('RDM 2D CFAR Target Detect (MTI)');
% else
%     imagesc(velocityAxis,rangeBin,detected_points_2D_static);
%     title('RDM 2D CFAR Target Detect (not MTI)');
% end
% xlabel('Velocity (m/s)');
% ylabel('Range (m)');
% yticks(0:2:max(rangeBin));
% colorbar;
% axis xy
% 
% %% Clustering plot
% nexttile;
% % plot DBSCAN clustering
% if dbscan_mode
%     if MTIfiltering
%        imagesc(velocityAxis, rangeBin, clusterGrid);
%        title('DBSCAN Clustering (MTI)');
%     else
%        imagesc(velocityAxis, rangeBin, clusterGrid_static);
%        title('DBSCAN Clustering (not MTI)');
%     end
% % Plot K-means Clustering
% else 
%     imagesc(velocityAxis,rangeBin,detected_points_clustering);
%     title('K-means Clustering');
% end
% xlabel('Velocity (m/s)');
% ylabel('Range (m)');
% yticks(0:2:max(rangeBin));
% axis xy
% colorbar;

%% Micro doppler plot
% plot
nexttile;
imagesc(time_axis,velocityAxis,sdb_mti);
xlabel('times (s)');
ylabel('Velocity (m/s)');
title('Micro Doppler');
colorbar;
axis xy

%% Range Time Map plot
% plot
nexttile;
imagesc(time_axis,rangeBin,sdb_rangetime');
xlabel('times (s)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('Range Time');
colorbar;
axis xy

%% 새로 짠 Angle FFT Plot
figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);
nexttile;
if MTIfiltering
    imagesc(angleBin,rangeBin,ram_output2_mti)
    title('Range Azimuth map MTI');
else
    imagesc(angleBin,rangeBin,ram_output2)
    title('Range Azimuth map not MTI');
end
xlabel('Angle( \circ)')
ylabel('Range(m)')
yticks(0:2:max(rangeBin));
colorbar;
axis xy

%% 새로 짠 Angle FFT 코드로 2D RAM CAOS-CFAR plot 
nexttile;
imagesc(angleBin,rangeBin,detected_points_2D_ram);
xlabel('Angle( \circ)');
ylabel('Range (m)');
yticks(0:2:max(rangeBin));
title('RAM 2D CFAR Target Detect');
colorbar;
axis xy;

%% 새로 짠 Angle FFT 코드로 1D azimuth plot
% RangeBinIdx -> plot에서 보고싶은 거리
angle_profile = squeeze(sum(abs(AngData(:,:,:)),1));
angle_profile_mti = squeeze(sum(abs(AngData_mti(:,:,:)),1));
nexttile;
if MTIfiltering
   plot(angleBin, angle_profile_mti)
   title('Angle Profile plot (MTI)');
else
   plot(angleBin, angle_profile)
   title('Angle Profile plot (not MTI)'); 
end
xlabel('Angle( \circ)')
ylabel('Amplitude')
yticks(0:2:max(rangeBin));

%% plot 3D point clouds
figure('Position', [300,100, 1200, 800]);
tiledlayout(2,2);
nexttile;
% x-direction: Doppler, y-direction: angle, z-direction: range
[axh] = scatter3(save_det_data_dynamic(:, 6), save_det_data_dynamic(:, 7), save_det_data_dynamic(:, 5), 'filled');
xlabel('Doppler velocity (m/s)')
ylabel('Azimuth angle (degrees)')
zlabel('Range (m)')
title('3D point clouds')
grid on

%% Detection & Angle estimation Results plot
nexttile;
hold on;
% dynamic target position plot
plot(target_x_dynamic, target_y_dynamic, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 5);
hold on;
% static target position plot
plot(target_x_static, target_y_static, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 5);
% radar position plot
hold on;
plot(0, 0, '^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);

% plot 범위 설정
axis([x_min, x_max, y_min, y_max]);
xlabel('X (m)');
ylabel('Y (m)');
title('Detection & Angle estimation Results');
grid on;
hold off;
% yticks(0:2:max_range);
% xticks(-max_range:2:max_range);

