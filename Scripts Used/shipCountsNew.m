function [coords, shipPts, shipCount] = shipCountsNew(image,lat,lon)
%   Note that this function needs the img_bounds function to limit the
%   lines defining the wakes within image bounds
%   coords - coordinates of the end points of line representing ship wake to be traced in the SAR image
%   ship_pts - ship coordinates
%   ship_count - inventory of ships in the image
%   image - [double/single] SAR image
%   lat - extent of image in latitude - format: [start end]
%   lon - extent of image in longitude - format: [start end]

% 2 Enhance the edges in the images
% Median filtering
J = medfilt2(image,[5,5]);

% Edge detection
% E = double(edge(J,"sobel"));
E = edge(J,"Canny",[0.1, 0.2]);

% % Multiply image
% prod = image.*E;

% 3 Take Radon transform and detect peaks
% Radon transform of edge-enhanced image
% Initialize angles
theta = 0:180;

% Take the Radon transform of the contrast-enhanced image E
[R, xp] = radon(E, theta);

% Divide values by the maximum possible value given the size
% norm_R = R*5/max_val;
norm_R = R./(max(R,[],"all")-min(R,[],"all"));

% Locate the maximum value/s with a certain threshold
rel_th = 0.95;
[row, col] = find(norm_R > rel_th);
% [row, col] = find(R > max_val);

% 4 Ship inventory
% Reduce number of peak values around separation distance/t in theta
sep_dis = 5;
[~,~,IA] = uniquetol(col,sep_dis,'DataScale',1);        % Index of unique values around some tolerance
unq_val = accumarray(IA,col,[],@(v) v(ceil(end/2)));    % Unique values but only the middle(odd)/lower(even) ones taken
[~, idx] = ismember(unq_val,col);                      % Identify indices (idx) of the unique values in original vector

% Filtered values
row = row(idx); col = col(idx);
peak_number = length(unq_val);                          % Number of peaks is also the number of ships detected within ROI

% Actual values in the Radon space
xp_pk = xp(row);                % Rotated x-axis, square root of the sum of squares of image dimensions
theta_pk = theta(col);          % Orientation of the rotated x-axis

% Locate center in the image
centerX = ceil(size(image,2)/2);
centerY = ceil(size(image,1)/2);

% Initialize values for the offset for the center of rotated axis
xy_off = zeros(peak_number,2);

for i = 1:peak_number
    
    % Calculate offsets from theta and xp peak values for shifted centers
    % center within the rotated axis 
    x_off = xp_pk(i)*cos(deg2rad(theta_pk(i)));
    y_off = xp_pk(i)*sin(deg2rad(theta_pk(i)));
    
    xy_off(i,:) = [x_off, y_off];
end

% Correcting image bounds
% xy_off - offset from the origin
sh_xy(:,1) = floor(xy_off(:,1) + centerX);
sh_xy(:,2) = floor(-xy_off(:,2) + centerY);

%%%%%%%%%%%%%%%%%%%%%%%%%Initialization%%%%%%%%%%%%%%%%%%%%%%%%%
epts = zeros(peak_number,4);
latlon_coord = zeros(peak_number,4);
lin_profile = cell(1,peak_number);
brightPeak = zeros(peak_number,1);
testPeak = zeros(peak_number,1);
% sh_latlong = zeros(peak_number,2);

sh_lat = zeros(peak_number,1);
sh_long = zeros(peak_number,1);

% Generate a vector that represents the lat-lon space of the image
longspace = linspace(lon(1),lon(2),size(E,2));
latspace = linspace(lat(1),lat(2),size(E,1));

for i = 1:peak_number
    % Calculate endpoints of wake within image bounds
    endpoints = img_bounds(size(image),sh_xy(i,:),theta_pk(i));
    
    % Reassigning image coordinates from calculation
    x_coord = [endpoints(1), endpoints(3)];
    y_coord = [endpoints(2), endpoints(4)];
    
    % Store image coordinates
    epts(i,:) = [x_coord,y_coord];
    
    % Convert image coordinates to WGS84
    lat_coord = latspace(y_coord);
    lon_coord = longspace(x_coord);

    % Store endpoints in lat-long coordinates
    latlon_coord(i,:) = [lat_coord, lon_coord];

    % Take the line profile of the line along the ship wake
    profile = improfile(image,x_coord,y_coord);

    % Filter NaN values
    non_nan_profile = profile(~isnan(profile));

    % Peak detection of the line profile
    [brightPeak(i), b_ind] = max(non_nan_profile);

    % Test if brightest peak is not part of background - image stats
    % criteria: imgst1 - 3std, imgst2 - 5std
    testPeak(i) = brightPeak(i) > (mean(image,"all") + 5*std(image,1,"all"));
    
    % Find the slope of the line defining the ship wake
    slope = (y_coord(1)-y_coord(2))/(x_coord(1)-x_coord(2));
   
    % Find ship coordinates in terms of image indices
    if slope == 0
        x_ind = b_ind;
        y_ind = y_coord(1);
    elseif slope == Inf
        x_ind = x_coord(1);
        y_ind = b_ind;
    else
        % slope = slope;

        % Generate vector space that represents image coordinates/indices
        xlin = linspace(x_coord(1),x_coord(2),length(non_nan_profile));
        ylin = linspace(y_coord(1),y_coord(2),length(non_nan_profile));
        
        % Ship coordinates relative to image
        x_ind = floor(xlin(b_ind)); 
        y_ind = floor(ylin(b_ind));

    end
   
    % Convert these image coordinates to lat-long points
    sh_lat(i) = latspace(floor(y_ind));
    sh_long(i) = longspace(floor(x_ind));
    
    % Store line profiles in a cell array
    lin_profile{i} = non_nan_profile';
end 

%%%%%%%%%%%%%%%%%%%%%%%%%Filtering peaks%%%%%%%%%%%%%%%%%%%%%%%%%
% Ensure testPeak is logical
testPeak = logical(testPeak);

% Determine output values
shipCount = sum(testPeak);   % Integer - number of ships detected

if shipCount > 0
    shipPts = [sh_lat(testPeak), sh_long(testPeak)];   % Double (could be multiple rows) - lat-long coordinates
    coords = latlon_coord(testPeak,:);  % Format lat1, lat2, lon1, lon2
else
    shipPts = [];
    coords = [];
end


end 
