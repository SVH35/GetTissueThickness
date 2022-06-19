
function [Output] = GTT(segDir, CoordOfInterest, ToPlot, nrOfPoints)

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

%% Code
tic

if nargin < 4 %number of points used if no input is supplied by user
    nrOfPoints = 5000;
end

if contains(struct2array(ver), 'Statistics and Machine Learning Toolbox') == 1 %checks if required toolboxes are installed
    if contains(struct2array(ver), 'Parallel Computing Toolbox') == 1 %checks if recommended toolboxes are installed
    else
        disp('Parallel Computing Toolbox is not installed, considering installing this toolbox to run GTT faster');
    end
else
    error('ERROR: Statistics and Machine Learning Toolbox is required to run this function but is not installed')
end

parentDir = fileparts(segDir);

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

if (-1<CoordOfInterest(1)) && (CoordOfInterest(1)<1) %if ROI is on the midline, ensure that normal is always going upwards (i.e., outwards)
    if N(3)<=0
        N = N * -1;
    end
else
    if (CoordOfInterest(1)>=0) && (N(1) <= 0) || (CoordOfInterest(1)<=0) && (N(1) >= 0) %if ROI is part of left/right hemishphere, ensure that normal is always going leftwards/rightwards (i.e., outwards)
        N = N * -1;
    end
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

% get CSF thickness
OutputCSF = Triangulation2Intersect(csf, intersectpoint_GM, N);
CSF_thickness = tissue_thickness(OutputCSF);
CSF_Thickness(1) = CSF_thickness{1}.t;
% get bone thickness
OutputBone = Triangulation2Intersect(bone, intersectpoint_GM, N);
bone_thickness = tissue_thickness(OutputBone);
Bone2GM(1) = bone_thickness{1}.t;
Bone_Thickness(1) = Bone2GM(1) - CSF_Thickness(1);
% get skin thickness
OutputSkin = Triangulation2Intersect(skin, intersectpoint_GM, N);
skin_thickness = tissue_thickness(OutputSkin);
Skin2GM(1) = skin_thickness{1}.t;
Skin_Thickness(1) = Skin2GM(1) - (CSF_Thickness(1) + Bone_Thickness(1));
% get scalp to cortex distance
ScalpToCortex = CSF_Thickness(1) + Bone_Thickness(1) + Skin_Thickness(1);

Output = table(CSF_Thickness,Bone_Thickness,Skin_Thickness,ScalpToCortex); %create output file

if ToPlot == 1 %plot results
    quiver3(m1coord_mesh(1),m1coord_mesh(2),m1coord_mesh(3),(N(1)*60),(N(2)*60),(N(3)*60),'Color','r') %plot normal (eigenvector 3)
    hold on
    %quiver3(m1coord_mesh(1),m1coord_mesh(2),m1coord_mesh(3),(GN1(1)*15),(GN1(2)*15),(GN1(3)*15),'Color','y') %plot eigenvector 1
    %hold on
    %quiver3(m1coord_mesh(1),m1coord_mesh(2),m1coord_mesh(3),(GN2(1)*15),(GN2(2)*15),(GN2(3)*15),'Color','b')%plot eigenvector 2
    %hold on
    plot3(intersectpoint_GM(1),intersectpoint_GM(2),intersectpoint_GM(3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
    hold on
    plot3(CSF_thickness{1,2}(1,1),CSF_thickness{1,2}(1,2),CSF_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
    hold on
    plot3(bone_thickness{1,2}(1,1),bone_thickness{1,2}(1,2),bone_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
    hold on
    plot3(skin_thickness{1,2}(1,1),skin_thickness{1,2}(1,2),skin_thickness{1,2}(1,3),'o','Color','#000000','MarkerSize',15,'MarkerFaceColor','#000000')
    hold on
    %plot3(ROI_coord(1),ROI_coord(2),ROI_coord(3),'o','Color','#000000','MarkerSize',15,'MarkerFaceColor','#000000')
    %hold on
    plot3(skin.Points(:,1),skin.Points(:,2),skin.Points(:,3),'o','Color','#D7B6A5','MarkerSize',1)
    %trimesh(skin,'facecolor', '#a88d6f', 'edgecolor', '#D7B6A5')
    hold on
    plot3(csf.Points(:,1),csf.Points(:,2),csf.Points(:,3),'o','Color','#008488','MarkerSize',1)
    %trimesh(csf,'facecolor', '#92c3f7', 'edgecolor', '#008488')
    hold on
    plot3(bone.Points(:,1),bone.Points(:,2),bone.Points(:,3),'o','Color','#CBCBCB','MarkerSize',1)
    %trimesh(bone,'facecolor', '#b3b3b3', 'edgecolor', '#CBCBCB')
    hold on
    plot3(gm.Points(:,1),gm.Points(:,2),gm.Points(:,3),'o','Color','#464646','MarkerSize',1)
    %trimesh(gm,'facecolor', '#949494', 'edgecolor', '#464646')
    hold on
    plot3(wm.Points(:,1),wm.Points(:,2),wm.Points(:,3),'o','Color','#F9F6EE','MarkerSize',1)
    %trimesh(wm,'facecolor', '#949494', 'edgecolor', '#F9F6EE')
%     hold on
%     w = null(N.'); 
%     [P,Q] = meshgrid(-15:15); 
%     coords = [m1coord_mesh(1)+w(1,1)*P+w(1,2)*Q, m1coord_mesh(2)+w(2,1)*P+w(2,2)*Q, m1coord_mesh(3)+w(3,1)*P+w(3,2)*Q];
%     surf(coords(1:31,1:31),coords(1:31,32:62),coords(1:31,63:93))
end

% if ToPlot == 1 %plot results
%     quiver3(m1coord_mesh(1),m1coord_mesh(2),m1coord_mesh(3),(N(1)*60),(N(2)*60),(N(3)*60),'Color','r') %plot normal (eigenvector 3)
%     hold on
%     quiver3(m1coord_mesh(1),m1coord_mesh(2),m1coord_mesh(3),(GN1(1)*15),(GN1(2)*15),(GN1(3)*15),'Color','y') %plot eigenvector 1
%     hold on
%     quiver3(m1coord_mesh(1),m1coord_mesh(2),m1coord_mesh(3),(GN2(1)*15),(GN2(2)*15),(GN2(3)*15),'Color','b')%plot eigenvector 2
%     hold on
%     hold on
%     plot3(intersectpoint_GM(1),intersectpoint_GM(2),intersectpoint_GM(3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
%     hold on
%     plot3(CSF_thickness{1,2}(1,1),CSF_thickness{1,2}(1,2),CSF_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
%     hold on
%     plot3(bone_thickness{1,2}(1,1),bone_thickness{1,2}(1,2),bone_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
%     hold on
%     plot3(skin_thickness{1,2}(1,1),skin_thickness{1,2}(1,2),skin_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
%     hold on
%     trimesh(skin,'facecolor', '#a88d6f', 'edgecolor', '#553000')
%     hold on
%     trimesh(csf,'facecolor', '#92c3f7', 'edgecolor', '#008488')
%     hold on
%     trimesh(bone,'facecolor', '#b3b3b3', 'edgecolor', '#CBCBCB')
%     hold on
%     trimesh(gm,'facecolor', '#949494', 'edgecolor', '#464646')
%     hold on
%     w = null(N.'); 
%     [P,Q] = meshgrid(-15:15); 
%     coords = [m1coord_mesh(1)+w(1,1)*P+w(1,2)*Q, m1coord_mesh(2)+w(2,1)*P+w(2,2)*Q, m1coord_mesh(3)+w(3,1)*P+w(3,2)*Q];
%     surf(coords(1:31,1:31),coords(1:31,32:62),coords(1:31,63:93))
% end
toc
end