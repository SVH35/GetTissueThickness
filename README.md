# GTT: GetTissueThickness

![GetTissueThickness Frontpage](/Documents/Figures/GTT_BANNER.png)

## Introduction
The main goal of GTT is to provide a systematic, automated and fast method to quantify the thickness of tissues in the scalp. By doing so, GTT aims to provide a tool to better understand how tissues and/or scalp-to-cortex distance influence non-invasive brain stimulation and source-localized neuroimaging. 

The GTT pipeline consists of four major parts:
1) load the segmented 3D tissues into the MATLAB environment and define a cortical region of interest
2) locate this region of interest in the grey matter and select the k-nearest points
3) find the plane-of-best fit of the selected points and the normal of this plane
4) measure the intersection of this normal with the most outer grey matter, cerebrospinal fluid, bone and skin voxels and calculate tissue thicknesses and scalp-to-cortex distance

## Authors
The following persons worked on this project
* Sybren Van Hoornweder
* Kevin A. Caulfield
* Marc Geraerts 
* Stefanie Verstraelen
* Raf L.J. Meesen

## How to cite
Pleaser cite the following article if you use the following script: TBP

## Requirements
The pipeline only requires [MATLAB](https://www.mathworks.com/products/matlab.html) to run. 

## Third party files
We have used code from the following projects in this repository:
* [SimNIBS](https://simnibs.github.io/simnibs/build/html/index.html)
* [Triangle/Ray Intersection](https://nl.mathworks.com/matlabcentral/fileexchange/33073-triangle-ray-intersection)

## Overview of the pipeline
To run the pipeline, download the [code](/Code). This section provides a short overview of the pipeline, a more in-depth discussion of the underlying methods can be found in the accompanying publication. 

### 0. Generate high-quality head models from MR images
Given that finite element head meshes are required, an algoritm capable of creating these head meshes based on T1w and T2w magnetic resonance image scans is required before being able to use GTT. We recommend [SimNIBS headreco](https://simnibs.github.io/simnibs/build/html/documentation/command_line/headreco.html).

### 1. Load the segmented 3D tissues into the MATLAB environment and define a cortical region of interest
Load the 3D tissues of interest into MATLAB and supply the MNI coordinate of the cortical region of interest. This coordinate will be transformed the subject space.

### 2. Locate this region of interest in the grey matter and select the k-nearest points
The 3D grey matter voxel closest to the cortical region of interest is located. The k-nearest points closest to this coordinate are retrieved. Per standard, 5000 points are selected. Values between 100 and 10,000 were originally explored, with 5000 points yielding the best results. These 5000 points, and the grey matter voxel closest to the cortical region of interest are stored in a data matrix. 

### 3. Find the plane-of-best fit of the selected points and the normal of this plane
[Principal component analysis](https://nl.mathworks.com/help/stats/pca.html) is performed on the aforementioned data matrix. Three eigenvectors and their eigennumbers are retrieved. The first two eigenvectors define the plane best describing the supplied data matrix (i.e., the cortical surface surround the region of interest). The third eigenvector is the normal of this plane, and is used to caculate the tissue thicknesses. Thus, the third eigenvector is the normal of the cortical surface. 

### 4. Measure the intersection of this normal with the most outer grey matter, cerebrospinal fluid, bone and skin voxels and calculate tissue thicknesses and scalp-to-cortex distance
Through the [Möller–Trumbore Ray/Triaingle intersection algorithm](https://nl.mathworks.com/matlabcentral/fileexchange/33073-triangle-ray-intersection), the intersection between the normal of the cortex (i.e., the third eigenvector) which runs through the cortical region of interest and the outer grey matter, cerebrospinal fluid, skull and skin layers are retrieved. From these intersection coordinates, the distances of the cerebrospinal fluid, skull and skin layers are calculated, as well as the scalp-to-cortex distance.


## Tutorial: Single Subject Pipeline Using the GTT.m Script
Overview: Steps 1-2 create the head mesh from MRI scans and Steps 3-6 use GTT to measure tissue thicknesses based on the head model created in Steps 1-2. If you want to skip step 1 and 2, you download the head model [here](https://drive.google.com/file/d/1hLk6LK7oE7EHSExLVKxkLyPb8GfBv8KB/view?usp=sharing).

### Steps 1-2: Creating the Head Mesh from T1w and T2w MRI scans

1. Download the [tutorial dataset](https://github.com/SVH35/GetTissueThickness/tree/main/Documents/Tutorial%20Dataset). The tutorial data include T1w and T2w MRI scans to mesh into a head model. If you prefer to skip step 2, you can also immediately donwload the meshed head model [here](https://drive.google.com/file/d/1hLk6LK7oE7EHSExLVKxkLyPb8GfBv8KB/view?usp=sharing). 

2. Create finite element head meshes from the downloaded T1w and T2w MRI scans. We recommend [SimNIBS headreco](https://simnibs.github.io/simnibs/build/html/documentation/command_line/headreco.html) (version 3.2) to do so. Although SimNIBS provides a comprehensive overview of this procedures, a short summary is given here for the sake of completeness.

    2.1. Open a terminal and navigate to the folder containing the T1w and T2w MRI scans
    
    2.2. Run the following command
  
    `headreco all Example_GTT Example_GTT_T1.nii Example_GTT_T2.nii` 
  
    *This command calls headreco using both SPM12 and CAT12, creating a headmesh named ‘Example_GTT’ from the T1 and T2 scans. The process takes               approximately 2 hours on a 8-core computer with 32GB of RAM.*
    
    *if a CPU-heavy computer is available, we recommend running headreco in a parellel for-loop to considerably decrease running time when working with       large datasets*
  
    2.3. Check results
  
    `headreco check Example_GTT`
    
     *This command opens a window allowing the user to compare the raw MRI scan and the head model containing meshed tissue segmentation layers.*
     
### Steps 3-6: Using GTT To Measure Tissue Thicknessess at the Region of Interest
    
3. Download the [code](/Code) and add it to your MATLAB path.
4. Add the m2m folder containing the subject mesh as a variable in matlab. For instance;

   `m2m_folder = C:\Users\SVH\GTT\m2m_Example_GTT';`

5. Add the coordinate of interest as a variable in MATLAB. For instance, for M1, the MNI coordinate would be x = -37, y = -21, z = 58 ([Mayka et al. 2007](https://doi.org/10.1016/j.neuroimage.2006.02.004)).

    `roi = [-37, -21, 58];`

6. Run the following command in MATLAB. The third argument should be 1 if you want to plot the results. The created figure will show all tissue layers (grey matter, cerebrospinal fluid, bone and skin), the grey matter plane, the grey matter normal and all intersection points. The fourth argument defines the total amount of nearby points you want to use to create the data matrix used in the principal component analysis. 

   `GTT(m2m_folder,roi, 1, 5000);`

Not suppressing the command (i.e. no semicolon) outputs a 1 x 4 table in the MATLAB Command Window, showing the CSF thickness, bone thickness, skin thickness, and scalp-to-cortex distance (sum of each tissue layer thickness). If the plot argument equals 1, the figure graphically showing the results is also displayed (for this figure, only the points of the triangulation matrix are shown (figure colors have been updated in final version of GTT). 

![GetTissueThickness Tutorial](/Documents/Figures/Figure_EX_Tutorial.png)

In this example, the CSF thickness was 10.8250 mm, the bone thickness was 7.0401 mm, the skin thickness was 6.2609 mm, and the scalp-to-cortex distance was 24.1260 mm (i.e., the sum of the CSF, bone and skin thickness). 

In the figure, the inner grey layer denotes the grey matter points, the blue layer denotes the CSF, the light grey layer denotes the skull and the brown layer denotes the skin. The intersection between the grey matter normal (red line) and the outer voxels of each layer is displayed by red spheres. The best-fit plane of the grey matter is shown by the yellow plane.

## License
This software runs under a GNU General Public License v3.0.

This software uses free packages from the Internet, except MATLAB, which is a proprietary software by the MathWorks. You need a valid Matlab license to run this software.
