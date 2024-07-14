function shipdetectFunction(tempFile, fileID)
% This function should be run after obtaining the calculated ship data - 
% counts per image tile, ship coordinates and ship wake endpoints.
% First part loads all the binary files that contain all the calculated
% values.
    load(tempFile);
    load('geoInfo_9b82_imgst2.mat');
    
    outputDir = '/Users/astisarwais/Documents/MATLAB/new_detections/FIG_9b82_imgst2';
    mkdir(outputDir);

    % Read shapefile
    ship_shp = shaperead('Ships.shp');
    
    % Extract ship coordinates from SAR images
    x = [ship_shp.X];
    y = [ship_shp.Y];

    % Loop over tiles
    for i = 1:iter(1)
        for j = 1:iter(2)

            % fprintf('Tile row %d, col %d\n', i, j);
    
            % Create figure
            fig = createFigure(i, j);
    
            % Image tile and data
            img_tile = imgtil{i, j};
            lon_tile = lon((j-1)*tile+1:j*tile);
            lat_tile = lat((i-1)*tile+1:i*tile);

            % Plot image tile
            plotImageTile(minI, maxI, lon_tile, lat_tile, img_tile);
    
            % Plot ships
            plotShips(i, j, ship_num, points, ships);

            
            % Identify points within the extent
            withinExtent = x >= lon_tile(1) & x <= lon_tile(end) & y <= lat_tile(1) & y>=lat_tile(end);
            
            if sum(withinExtent)
                % There is ground truth point within bounds
                % Plot ground truth
                plotGroundTruth(x(withinExtent),y(withinExtent));

            end
            
            % Set axis ratio to 1:1
            axis tight equal;

            % Add legend
            legend('FontSize', 10,'Location','southeastoutside','Units','normalized');
    
            % Save the plot
            fig_name = sprintf('ImageTile%d_%d', i, j);
            saveas(fig, fullfile(outputDir, [fig_name, '.fig']));
    
            % Close the figure
            close(fig);
        end
    end
end

% Functions
function fig = createFigure(i, j)
    fig_name = sprintf('ImageTile%d_%d', i, j);
    fig = figure('Name', fig_name, 'NumberTitle', 'off', 'ToolBar', 'none');
    colormap gray;
    colorbar;
end

function plotImageTile(minI, maxI, lon_tile, lat_tile, img_tile)
    tickformat = '%.2f0';
    imagesc(lon_tile, lat_tile, img_tile);
    % title(fig_name);
    xtickformat(tickformat);
    ytickformat(tickformat);
    xlabel('Longitude','FontSize',14)
    ylabel('Latitude','FontSize',14)
    clim([minI, maxI]);
    set(gca, 'YDir', 'normal');
    hold on;
end

function plotShips(i, j, ship_num, points, ships)
    for k = 1:ship_num(i, j)
        % This ensures that only the first iteration is displayed only in
        % the legend.
        if k == 1
        % First iteration - Visibility is on
            plot(points{i, j}(k,3:4), points{i, j}(k,1:2), 'r-', 'LineWidth', 2, ...
            'DisplayName','Ship Wake');
            plot(ships{i, j}(:, 2), ships{i, j}(:, 1), '+', 'LineWidth', 3, ...
            'MarkerSize', 10, 'MarkerFaceColor', '#4DBEEE', 'MarkerEdgeColor', '#4DBEEE', ...
            'DisplayName','Ship Centroid along Wake');
        else
        % Next iterations - Visibility is off
        plot(points{i, j}(k,3:4), points{i, j}(k,1:2), 'r-', 'LineWidth', 2, ...
            'DisplayName','Ship Wake','HandleVisibility', 'off');
        plot(ships{i, j}(:, 2), ships{i, j}(:, 1), '+', 'LineWidth', 3, ...
            'MarkerSize', 10, 'MarkerFaceColor', '#4DBEEE', 'MarkerEdgeColor', '#4DBEEE', ...
            'DisplayName','Ship Centroid along Wake','HandleVisibility', 'off');
        end
    end
end

function plotGroundTruth(x,y)
    plot(x, y, '+', 'MarkerSize', 10, 'LineWidth', 3, ...
        'MarkerFaceColor', '#EDB120', 'MarkerEdgeColor', '#EDB120', ...
        'DisplayName','Actual Ship location (Ground-truth)','HandleVisibility', 'on');
end

