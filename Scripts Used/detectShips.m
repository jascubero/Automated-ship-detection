clc;
clear;

% Read geotiff and assign R as the metadata of the image
% Note that image here is in terms of raw sigma naught - radar
% cross-section in dB

filename = 'Clipped2_S1A_IW_GRDH_1SDV_20230919T215419_20230919T215444_050402_0611BB_9B82_Orb_Bdr_tnr_Cal_TC_dB.tif';
[I, lim] = readgeoraster(filename,"OutputType","double");

%% Define image limits

% Latitude and Longitude Limits of image
latlim = lim.LatitudeLimits;
lonlim = lim.LongitudeLimits;

% Generate vectors for the latitude and longitude
lat = linspace(latlim(2),latlim(1) ,size(I,1));
lon = linspace(lonlim(1),lonlim(2) ,size(I,2));

% Extrema of image
[minI, maxI] = bounds(I(:));

%% Image Tiling Prerequisites

% Size of image
[rows, cols] = size(I);

% Choose a tile size
tile = 512;

% Iterations
iter = floor(size(I)/tile);

% Calculate the remaining pixels
remainder = size(I) - iter*tile;

%% Peak Detection

% Initialize cell that contains orignal image
imgtil = cell(iter);

% Endpoints of the line defining the ship wake
points = cell(iter);

% Counts of ships detected
ship_num = zeros(iter);

% Coordinates of detected ships in image
ships = cell(iter);

% Image bounds in lat-long coordinates
lims = cell(iter);

% Loop per image tile
for i = 1:iter(1)
    for j = 1:iter(2)
        % Determine row indices for the current tile
        startRow = (i-1) * tile + 1;
        if i == iter(1)
            endRow = rows;  % Include remaining rows in the last iteration
        else
            endRow = i * tile;
        end
        
        % Determine column indices for the current tile
        startCol = (j-1) * tile + 1;
        if j == iter(2)
            endCol = cols;  % Include remaining columns in the last iteration
        else
            endCol = j * tile;
        end
        
        % Divide image into tiles
        imgTile = I(startRow:endRow, startCol:endCol);
        
        % Store tile image in a cell
        imgtil{i,j} = imgTile;

        % Define image boundaries
        % col - x/long, row - y/lat
        lims{i,j} = [lon(startCol), lon(endCol), lat(startRow), lat(endRow)];
        
        % Filtering only some valid images
        if std(imgTile,1,"all") > 0

            % Perform detection per image tile
            % [coords, shipPts, shipCount] = shipCountsNoEn(imgTile, xlims, ylims);

            % Perform detection per image tile
            [coords, shipPts, shipCount] = shipCountsNew(imgTile,lims{i,j}(3:4),lims{i,j}(1:2));
    
            % Store endpoints of the line defining ship wake
            points{i,j} = coords;
    
            % Store detected ship inventory per tile
            ship_num(i,j) = shipCount;
            
            % Store ship coordinates on the line along wake
            ships{i,j} = shipPts;
        % else
        %     disp('Standard deviation of image is zero.');
        end 
    end
end

disp('Finished ship and ship wake detection. Saving variables.')

%%  Saving variables

% Save variables as temporary files
tempFile = ['all_variables_9b82_imgst2','.mat'];

% save(tempFile, 'points','shipNum', 'ships', 'imgTilCell', 'iter', 'tileSize');
save(tempFile, 'points','ship_num', 'ships', 'imgtil', 'iter', 'tile', 'minI', 'maxI', '-v7.3');
save('geoInfo_9b82_imgst2.mat', 'lim', 'lat', 'lon', 'lims' );

disp("Finished saving variables.");

