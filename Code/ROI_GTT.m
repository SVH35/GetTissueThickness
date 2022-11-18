function [Output] = ROI_GTT(segDir, CoordOfInterest, ToPlot, nrOfPoints,ROI,Cortex)

%% GTT
%% General information
% This script requires 3 mandatory inputs and 1 non-mandatory input.

% Input 1: the directory containing the segmented tissues (.stl) format.
% Typically, this directory ends with 'm2m_SubjectName'.

% Input 2: Coordinates of interest in MNI space. For instance, M1
% coordinates are [-37 -21	58].

% Input 3: Plot results or not? If == 1, results are plotted.

% Input 4: Number of points used to create grey matter plane of best fit.
% Per default, 5000 points are used.

% Input 5 (ROI): Size of radius of ROI for thickness measurements

% Input 6 (Cortex): If cortical thickness should be measured,
% if == 1, cortical thickness is measured.

% example: thickness_OA1 = ROI_GTT('/Volumes/Data/OA_1/m2m_OA_1',[-37 -21 58], 1, 5000, 3, 1)

%% Code
tic

if nargin < 4 %number of points used if no input is supplied by user
    nrOfPoints = 5000; end

if contains(struct2array(ver), 'Statistics and Machine Learning Toolbox') == 1 %checks if required toolboxes are installed
    if contains(struct2array(ver), 'Parallel Computing Toolbox') == 1 %checks if recommended toolboxes are installed
    else; disp('Parallel Computing Toolbox is not installed, considering installing this toolbox to run GTT faster'); end
else; error('ERROR: Statistics and Machine Learning Toolbox is required to run this function but is not installed'); end

disp('Loading in tissues'); %loads in segmented tissues (triangulation matrices)

skin = stlread([segDir filesep 'skin.stl']);
bone = stlread([segDir filesep 'bone.stl']);
csf  = stlread([segDir filesep 'csf.stl']);
gm   = stlread([segDir filesep 'gm.stl']);
wm   = stlread([segDir filesep 'wm.stl']);

ROI_coord = mni2subject_coords(CoordOfInterest, segDir, 'nonl'); %transforms MNI coordinate to subject space, part of SimNIBS

gm1 = abs(gm.Points - ROI_coord); %finds 3D grey matter point closest to subject space coordinate of interest and uses this for further computations
gmtotal = sum(gm1,2);
[M,I] = min(gmtotal);
m1coord_mesh = gm.Points(I,:);

disp('Creating plane best fitting grey matter ROI and its normal');
gm_plane = abs(gm.Points-m1coord_mesh); %find plane of best fit based on k-nearest grey matter points to coordinate of interest
gmtotal_plane = sum(gm_plane,2);
gmtotal = sum(gm1,2);
gmtotal(:,2) = 1:length(gmtotal);
gmtotal = sortrows(gmtotal,1,'ascend');
idx = gmtotal(1:nrOfPoints,2);
gm_plane1 = gm.Points(idx,:);
N = pca(gm_plane1);
GN1 = N(:,1);
GN2 = N(:,2);
N = N(:,3); %normal of the plane of best fit (i.e., normal of grey matter plane)

%ensure that normal is going outwards
if (-1<CoordOfInterest(1)) && (CoordOfInterest(1)<1)
    if N(3)<=0; N = N * -1; end
else
    if (CoordOfInterest(1)>=0) && (N(1) <= 0) || (CoordOfInterest(1)<=0) && (N(1) >= 0); N = N * -1; end
end

disp('Calculating tissue thicknesses');

% tissue gm
OutputGM = Triangulation2Intersect(gm, m1coord_mesh, N);
[~,index] = sortrows([OutputGM.intersect].'); OutputGM = OutputGM(index(end:-1:1)); clear index
outputGM_T = struct2table(OutputGM);
if sum(outputGM_T{:,1}) == 1 %take outer grey matter voxel for further distance calculations
    Output_GM{1} = OutputGM(1);
    intersectpoint_GM = OutputGM(1).xcoor;
else
    OutputGM = OutputGM(1:sum(outputGM_T{:,1}));
    [~,index] = sortrows([OutputGM.t].'); OutputGM = OutputGM(index(end:-1:1)); clear index
    Output_GM{1} = OutputGM(1);
    intersectpoint_GM = OutputGM(1).xcoor;
end

%% Get ROI mask
inside = false(length(gm_plane1),1);
for i = 1:length(gm_plane1)
    center = intersectpoint_GM;
    d_PointCenter = sqrt(sum(([gm_plane1(i,1),gm_plane1(i,2),gm_plane1(i,3)]-center) .^ 2));
    inside(i) = (ROI>=d_PointCenter);
end
inside = inside';

ROI_mask = zeros(length(gm_plane1),1);
for i = 1:length(gm_plane1)
    ROI_mask(i,1:3) = [inside(i)*gm_plane1(i,1),inside(i)*gm_plane1(i,2),inside(i)*gm_plane1(i,3)];
end
ROI_mask = ROI_mask(any(ROI_mask,2),:);

%%
for index = 1:height(ROI_mask)
    disp(strcat('run_',num2str(index), '_of_',num2str(height(ROI_mask)),'_(',num2str((index/height(ROI_mask)*100)),'%)'));
    GMPOI = [ROI_mask(index,1),ROI_mask(index,2),ROI_mask(index,3)];
    
    % get cortical thickness
    if Cortex == 1
        gm_thickness = cortical_thickness(wm, gm, GMPOI);
        CORTICAL_Thickness(1) = gm_thickness;
    end
    
    % get CSF thickness
    OutputCSF = Triangulation2Intersect(csf, GMPOI, N);
    CSF_thickness = tissue_thickness(OutputCSF);
    CSF_Thickness(1) = CSF_thickness{1}.t;
    % get bone thickness
    OutputBone = Triangulation2Intersect(bone, GMPOI, N);
    bone_thickness = tissue_thickness(OutputBone);
    Bone2GM(1) = bone_thickness{1}.t;
    Bone_Thickness(1) = Bone2GM(1) - CSF_Thickness(1);
    % get skin thickness
    OutputSkin = Triangulation2Intersect(skin, GMPOI, N);
    skin_thickness = tissue_thickness(OutputSkin);
    Skin2GM(1) = skin_thickness{1}.t;
    Skin_Thickness(1) = Skin2GM(1) - (CSF_Thickness(1) + Bone_Thickness(1));
    % get scalp to cortex distance
    ScalpToCortex = CSF_Thickness(1) + Bone_Thickness(1) + Skin_Thickness(1);
    
    %create output file
    if Cortex == 1; Output(index,:) = table(CORTICAL_Thickness,CSF_Thickness,Bone_Thickness,Skin_Thickness,ScalpToCortex);  %#ok<AGROW>
    else; Output(index,:) = table(CSF_Thickness,Bone_Thickness,Skin_Thickness,ScalpToCortex); end %#ok<AGROW>
    
    if ToPlot == 1 %plot results
        quiver3(GMPOI(1),GMPOI(2),GMPOI(3),(N(1)*60),(N(2)*60),(N(3)*60),'Color','r'); hold on
        plot3(GMPOI(1),GMPOI(2),GMPOI(3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000'); hold on
        plot3(CSF_thickness{1,2}(1,1),CSF_thickness{1,2}(1,2),CSF_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000'); hold on
        plot3(bone_thickness{1,2}(1,1),bone_thickness{1,2}(1,2),bone_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000'); hold on
        plot3(skin_thickness{1,2}(1,1),skin_thickness{1,2}(1,2),skin_thickness{1,2}(1,3),'o','Color','#000000','MarkerSize',15,'MarkerFaceColor','#000000'); hold on
    end
end

if ToPlot == 1 %plot results
    trimesh(gm,'facecolor', '#A3859C', 'edgecolor', '#7B6979'); hold on
    trimesh(csf,'facecolor', '#97DDFB', 'edgecolor', '#6AA6F8'); hold on
    trimesh(bone,'facecolor', '#E5D7A1', 'edgecolor', '#C3B789'); hold on
    trimesh(skin,'facecolor', '#A27440', 'edgecolor', '#724D23');
end; toc
end
