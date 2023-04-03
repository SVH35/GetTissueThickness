# GTT: GetTissueThickness

![GetTissueThickness Frontpage](/GTT_banner1.png)

## Introduction
The primary objective of GTT is to provide a systematic, automated and fast method to quantify the thickness of tissues in the head. In doing so, GTT aims to provide a tool to understand and control for the influence of tissues on non-invasive brain stimulation and neuroimaging. 

The GTT pipeline is discussed in the following this study: TBA


## Authors
The following persons worked on this project
* Sybren Van Hoornweder
* Marc Geraerts 
* Stefanie Verstraelen
* Marten Nuyts
* Kevin A. Caulfield
* Raf L.J. Meesen

## How to cite
Pleaser cite the following article if you use the following script: TBP

## Requirements
The pipeline requires [MATLAB](https://www.mathworks.com/products/matlab.html) and [SimNIBS](https://simnibs.github.io/simnibs/build/html/index.html) to run. 

## Contingencies
We have used code from the following projects in this repository:
* [SimNIBS] (https://simnibs.github.io/simnibs/build/html/index.html)
* [Triangle/Ray Intersection](https://nl.mathworks.com/matlabcentral/fileexchange/33073-triangle-ray-intersection)
* [PointTriangleDistance] (https://www.mathworks.com/matlabcentral/fileexchange/22857-distance-between-a-point-and-a-triangle-in-3d?s_tid=FX_rc1_behav)

## Overview of the pipeline
To run the pipeline, download the [code](/Code). An more in-depth discussion of the underlying methods can be found in the accompanying publication. Make sure that the SimNIBS - matlab path is added to the MATLAB environment.

GTT consists of three steps: preparation, initation, and measurement. It requires a structure, as input, containing the following arguments:
* structure.Mesh (Path containing head mesh obtained by CHARM, e.g., ...\m2m_subject1)
* structure.Fiducial (Starting coordinate, e.g., −52.2	−16.4	57.8)
* structure.FiducialType (Coordinate space, can be MNI or Subject space	Subject)
* structure.BeginTissue	(Whether structure.Coord is a scalp [SCALP] or grey matter [GM] coordinate)
* structure.PlotResults (Boolean statement if results should [1] or should not be plotted [1])
 
Examples of the GTT graphical output are shown below:
![GetTissueThickness Frontpage](/GTT_OUTPUT.png)
![GetTissueThickness Frontpage](/GTT_OUTPUT1.png)

## License
This software runs under a GNU General Public License v3.0.

This software uses free packages from the Internet, except MATLAB, which is a proprietary software by the MathWorks. You need a valid Matlab license to run this software.
