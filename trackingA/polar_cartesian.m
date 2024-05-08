close all;
figure;tiledlayout(1, 2);

nexttile;
cart_data_dynamic = flipud((flipud(mag_data_dynamic))');
%x_axis_cart = -abs(max(rangeBin)):abs(max(rangeBin));
x_axis_cart = -90.00 : 90.00;
yaxiscart = 0:abs(max(rangeBin)); 
y_axis_cart = flipud(yaxiscart');
imagesc(x_axis_cart, y_axis_cart, cart_data_dynamic);
set(gca, 'YDir', 'normal');
title('Range Azimuth'); xlabel('angle(degres)'); ylabel('meters(m)');

nexttile;
if STATIC_ONLY == 1
    if log_plot
        surf(y_axis, x_axis, (mag_data_static).^0.4,'EdgeColor','none');
    else
        surf(y_axis, x_axis, abs(mag_data_static),'EdgeColor','none');
    end
else
    if log_plot
        surf(y_axis, x_axis, (mag_data_dynamic).^0.4,'EdgeColor','none');
    else
        surf(y_axis, x_axis, abs(mag_data_dynamic),'EdgeColor','none');
    end
end

view(2); colorbar;
title('Cartesian'); xlabel('meters(m)'); ylabel('meters(m)');