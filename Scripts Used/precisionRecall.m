clc; clear;

load("all_variables_9b82_imgst2.mat");
load("geoInfo_9b82_imgst2.mat");

%% Take all the predicted coordinates of ships

% Initialize a matrix to store the coordinates
[rows, cols] = size(ships);
shipPoints = [];

% Loop through the cell array and fill the matrix
for i = 1:rows
    for j = 1:cols
        if any(ships{i,j})
            shipPoints = [shipPoints; ships{i, j}];

        end
    end
end

% We flip to reverse the order and make the format long(x), lat (y)
shipPoints = flip(shipPoints,2);

% Read shapefile of ground-truth points
ship_shp = shaperead('Ships.shp');

% Extract ship coordinates from SAR images
groundTruth = [[ship_shp.X]', [ship_shp.Y]'];

% Set headers for the csv
header = {"Longitude", "Latitude"};

% Fuse headers to data
mainCell = [header; num2cell(shipPoints)];

% Write as csv
writecell(mainCell,"predShipCoordinates_9b82_imgst2.csv");

%% Match predicted to ground truth points

% Set a distance threshold to consider a prediction as a true positive
% distanceThreshold = 15.5*lim.CellExtentInLongitude;
distanceThreshold = 20*lim.CellExtentInLongitude;

% Initialize counts
truePositives = 0;
falsePositives = 0;
% falseNegatives = 0;

TP = []; FP = []; FN = [];

% Match predictions to ground truth
for i = 1:size(shipPoints, 1)
    minDistance = inf;
    for j = 1:size(groundTruth, 1)
        distance = norm(shipPoints(i, :) - groundTruth(j, :));
        if distance < minDistance
            minDistance = distance;
        end
    end
    if minDistance <= distanceThreshold
        truePositives = truePositives + 1;
        TP = [TP; shipPoints(i,:)];
    else
        falsePositives = falsePositives + 1;
        FP = [FP; shipPoints(i,:)];
    end
end

% Calculate false negatives
falseNegatives = size(groundTruth, 1) - truePositives;

% Calculate precision and recall
precision = truePositives / (truePositives + falsePositives);
recall = truePositives / (size(groundTruth, 1));
f1score = 2*((precision*recall)/ (precision+recall));

% Precision: 0.76
% Recall: 0.81
% F1-Score: 0.79
% FP 11, FN 8, TP 35

% Display results
fprintf('Precision: %.2f\n', precision);
fprintf('Recall: %.2f\n', recall);
fprintf('F1-Score: %.2f\n', f1score);

% True negatives are generally not applicable in object detection but can be inferred in specific contexts
% For simplicity, we assume true negatives are zero here
trueNegatives = 0;

% Calculate confusion matrix
confusionMatrix = [
    truePositives, falsePositives;
    falseNegatives, trueNegatives
];

%% Confusion matrix

% Visualize the confusion matrix
figure;
imagesc(confusionMatrix);
colormap sky;
% colorbar;
title('Confusion Matrix', 'FontSize', 28);
xlabel('Actual');
ylabel('Predicted');
xticks([1 2]);
yticks([1 2]);
xticklabels({'Positive', 'Negative'});
yticklabels({'Positive', 'Negative'});
text(1, 1, num2str(confusionMatrix(1,1)), 'FontSize', 20, 'Color', 'k', 'HorizontalAlignment', 'center');
text(2, 1, num2str(confusionMatrix(1,2)), 'FontSize', 20, 'Color', 'k', 'HorizontalAlignment', 'center');
text(1, 2, num2str(confusionMatrix(2,1)), 'FontSize', 20, 'Color', 'k', 'HorizontalAlignment', 'center');
text(2, 2, num2str(confusionMatrix(2,2)), 'FontSize', 20, 'Color', 'k', 'HorizontalAlignment', 'center');

%% Plot points

figure; 

% Plot ship points
h1 = plot(shipPoints(:,1), shipPoints(:,2), '+', 'LineWidth', 2, ...
    'MarkerSize', 10, 'MarkerFaceColor', '#4DBEEE', 'MarkerEdgeColor', '#4DBEEE', ...
    'DisplayName', 'Ship Centroid along Wake');

hold on; 

% Plot ground truth points
h2 = plot(groundTruth(:,1), groundTruth(:,2), '+', 'MarkerSize', 10, 'LineWidth', 2, ...
    'MarkerFaceColor', '#EDB120', 'MarkerEdgeColor', '#EDB120', ...
    'DisplayName', 'Actual Ship location (Ground-truth)');

% Plot ground truth points
h3 = plot(TP(:,1), TP(:,2), '^', 'MarkerSize', 7, 'LineWidth', 2, ...
    'MarkerFaceColor', '#EDB120', 'MarkerEdgeColor', '#D95319', ...
    'DisplayName', 'True Positives');

% Add legend
legend([h1, h2, h3], 'FontSize', 10, 'Location', 'southwest', 'Units', 'normalized');
