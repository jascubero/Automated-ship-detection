# Automated ship detection on Synthetic Aperture Radar (SAR) images from Ocean wakes
This repository contains all the materials used for the paper *"Automated ship detection on Synthetic Aperture Radar (SAR) images from Ocean wakes"* by Cubero, J.H. and Soriano, M.N. which can be accessed via [Link to SPP Proceedings](https://proceedings.spp-online.org/article/view/SPP-2024-PD-15).

The image that was used in this study was **S1A_IW_GRDH_1SDV_20230919T215419_20230919T215444_050402_0611BB_9B82.tif** which was downloaded from the Copernicus Data Space Ecosystem. For masking, the Philippine National Administrative Boundaries from NAMRIA and PSA was used which was accessed via [Humanitarian Data Exchange](https://data.humdata.org/dataset/cod-ab-phl). 

All codes in **Scripts** folder are written in Matlab.

# Automated Ship Detection - MATLAB Scripts

This folder contains codes written in MATLAB for automated ship detection using SAR images. The primary functions include `detectShips.m`, `shipCountsNew.m`, `img_bounds.m`, `shipdetectFunction.m`, and `precisionRecall.m`. Below is a detailed description of each script and its functionality.

## detectShips.m
This is the main function that calculates ship location and wake parameters. It calls the function `shipCountsNew.m` to perform these calculations and saves the results, along with geographic information, in binary MAT files for subsequent processing.

- **Input**: SAR image filename (masked image already)
- **Output**: `all_variables_xxxx_xxxx.mat`, `geoInfo_xxxx_xxxx.mat`

## shipCountsNew.m
This function is executed within a loop to process image tiles, determine ship locations, and count the ships. The steps involved are:

1. Image enhancement
2. Radon transform
3. Ship inventory and alignment of geographic information
4. Locating ships from the line profile
5. Filtering false peaks

- **Outputs**:
  - `coords`: Coordinates of the endpoints of the line representing the ship wake
  - `shipPts`: Ship coordinates
  - `shipCount`: Inventory of ships in the image
- **Inputs**:
  - `image`: SAR image tile
  - `lat`: Extent of the image in latitude
  - `lon`: Extent of the image in longitude

## img_bounds.m
This function limits the endpoints of the lines representing ship wakes to within the image bounds. It clips the length of these lines to fit within the SAR image.

- **Inputs**: Image size, point of origin shifted based on the peak detected from the Radon transform, orientation of the projection axis

## shipdetectFunction.m
This function should be run after obtaining calculated ship data counts per image tile, ship coordinates, and ship wake endpoints. It loads all the binary files with the calculated values and includes several subfunctions for visualization and saving plots.

- **Subfunctions**:
  - `createFigure(i, j)`: Creates a figure for the plots
  - `plotImageTile(minI, maxI, lon_tile, lat_tile, img_tile)`: Visualizes the image tile
  - `plotShips(i, j, ship_num, points, ships)`: Plots previously calculated ship coordinates
  - `plotGroundTruth(x, y)`: Plots ground-truth/actual ship coordinates

- **To Change**:
  - `outputDir`: Output directory
  - `ship_shp`: Shapefile for the ground-truth ships

## precisionRecall.m
This function calculates the precision and recall of the identified ships to evaluate the algorithm's performance. It loads the previously saved binary files, identifies true positives, false positives, and false negatives, and calculates the confusion matrix. It also visualizes all identified ships, ground-truth ships, and true positives in a single plot.

