function [Output] = CalcTissueThickness(segDir, CoordOfInterest, ToPlot, nrOfPoints)

tic
% coordinates of interest should be in MNI space
% Set the optional variables if omitted

if nargin < 4
    nrOfPoints = 5000;
end

parentDir = fileparts(segDir);

skin = stlread([segDir filesep 'skin.stl']);
bone = stlread([segDir filesep 'bone.stl']);
csf  = stlread([segDir filesep 'csf.stl']);
gm   = stlread([segDir filesep 'gm.stl']);
wm   = stlread([segDir filesep 'wm.stl']);

ROI_coord = mni2subject_coords(CoordOfInterest, segDir, 'nonl');
gm1 = abs(gm.Points - ROI_coord);
gmtotal = sum(gm1,2);  %Sum over dimension 2 (= horizontal)

[M,I] = min(gmtotal);
m1coord_mesh = gm.Points(I,:);

% create perpendicular line on ROI centre
gm_plane = abs(gm.Points-m1coord_mesh);

gmtotal_plane = sum(gm_plane,2);
gmtotal = sum(gm1,2);
gmtotal(:,2) = 1:length(gmtotal);
gmtotal = sortrows(gmtotal,1,'ascend');
idx = gmtotal(1:nrOfPoints,2); %max value is amount of points used to calculate plane normal
gm_plane1 = gm.Points(idx,:);

N = pca(gm_plane1);
N = N(:,3);

if (-1<CoordOfInterest(1)) && (CoordOfInterest(1)<1) %if ROI is on the midline, ensure that normal is always going upwards (i.e., outwards)
    if N(3)<=0
        N = N * -1;
    end
else
    if (CoordOfInterest(1)>=0) && (N(1) <= 0) || (CoordOfInterest(1)<=0) && (N(1) >= 0) %if ROI is part of left/right hemishphere, ensure that normal is always going leftwards/rightwards (i.e., outwards)
        N = N * -1;
    end
end

%% get correct vertices
% tissue gm
OutputGM = Triangulation2Intersect(gm, m1coord_mesh, N);

[~,index] = sortrows([OutputGM.intersect].'); OutputGM = OutputGM(index(end:-1:1)); clear index
outputGM_T = struct2table(OutputGM);
if sum(outputGM_T{:,1}) == 1
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

%% create output file
Output = table(CSF_Thickness,Bone_Thickness,Skin_Thickness,ScalpToCortex);

if ToPlot == 1
    quiver3(m1coord_mesh(1),m1coord_mesh(2),m1coord_mesh(3),(N(1)*60),(N(2)*60),(N(3)*60),'Color','r')
    hold on
    plot3(intersectpoint_GM(1),intersectpoint_GM(2),intersectpoint_GM(3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
    hold on
    plot3(CSF_thickness{1,2}(1,1),CSF_thickness{1,2}(1,2),CSF_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
    hold on
    plot3(bone_thickness{1,2}(1,1),bone_thickness{1,2}(1,2),bone_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
    hold on
    plot3(skin_thickness{1,2}(1,1),skin_thickness{1,2}(1,2),skin_thickness{1,2}(1,3),'o','Color','#ff0000','MarkerSize',10,'MarkerFaceColor','#ff0000')
    hold on
    plot3(skin.Points(:,1),skin.Points(:,2),skin.Points(:,3),'o','Color','#a88d6f','MarkerSize',3,'MarkerFaceColor','#a88d6f')
    hold on
    plot3(csf.Points(:,1),csf.Points(:,2),csf.Points(:,3),'o','Color','#92c3f7','MarkerSize',3,'MarkerFaceColor','#92c3f7')
    hold on
    plot3(bone.Points(:,1),bone.Points(:,2),bone.Points(:,3),'o','Color','#b3b3b3','MarkerSize',3,'MarkerFaceColor','#b3b3b3')
    hold on
    plot3(gm.Points(:,1),gm.Points(:,2),gm.Points(:,3),'o','Color','#949494','MarkerSize',3,'MarkerFaceColor','#949494')
    hold on
    hold on
    w = null(N.'); % Find two orthonormal vectors which are orthogonal to v
    [P,Q] = meshgrid(-15:15); % Provide a gridwork (you choose the size)
    X = m1coord_mesh(1)+w(1,1)*P+w(1,2)*Q; % Compute the corresponding cartesian coordinates
    Y = m1coord_mesh(2)+w(2,1)*P+w(2,2)*Q; %   using the two vectors in w
    Z = m1coord_mesh(3)+w(3,1)*P+w(3,2)*Q;
    surf(X,Y,Z)
end

toc
end