function  [Output] = GTT(input)

%% GTT
%% General information
%GTT requires a structure as input, containing the following fields

%input.Mesh=            path containing mesh

%input.Fiducial=        coordinate

%input.FiducialType=    coordinate space, can be MNI or Subject

%input.BeginTissue=     can be either SCALP or GM, defines if SCD or CSD
                        %has to be measured

%input.PlotResults=     should be 1 if a visual output has to be produced|

%input.Direction=       should not exist if a standard SCD/CSD measurement
                        %should be performed. If it exists, it calculates
                        %the SCD/CSD based on the given direction. The
                        %orientation should be an 1x3 array, indicating the
                        %direction to use (e.g., the z-axis of the TMS coil
                        %per SimNIBS convention)
                        %if input.Direction is set, BeginTissue should be
                        %scalp
%% Code
tic

if license('test','statistics_toolbox') == 1 %checks if required toolboxes are installed
    if license('test','Distrib_Computing_Toolbox') == 1 %checks if recommended toolboxes are installed
    else; disp('Parallel Computing Toolbox is not installed, consider installing for faster perfomance'); end
else; error('ERROR: Statistics and Machine Learning Toolbox is required'); end

%% Get mesh and create triangulation per tissue type
disp('Loading in tissues');
cd(input.Mesh); HeadMesh = dir('*.msh');

head_mesh = mesh_load_gmsh4(HeadMesh.name);
[wm,gm,csf,softtissue,~,bone_compact,bone_spongy,blood,~,volumes] = Mesh2Triangulation(head_mesh);

if input.FiducialType == "Subject"
    ROI_coord = input.Fiducial;
else; ROI_coord = mni2subject_coords(input.Fiducial, input.Mesh, 'nonl');
end

if input.BeginTissue == "SCALP"
    softtissue_surf_coord = findClosest3DCoord(softtissue.Points,ROI_coord);
    gm_surf_coord = findClosest3DCoord(gm.Points,ROI_coord);
elseif input.BeginTissue == "GM"
    gm_surf_coord = findClosest3DCoord(gm.Points,ROI_coord);
    softtissue_surf_coord = findClosest3DCoord(softtissue.Points,ROI_coord);
end
SphereSize = ceil(norm(gm_surf_coord - softtissue_surf_coord))*2;

disp('Calculating tissue thicknesses');
gm_subsection = getSubsection(gm, gm_surf_coord, SphereSize);
wm_subsection = getSubsection(wm, gm_surf_coord, SphereSize);
csf_subsection = getSubsection(csf, gm_surf_coord, SphereSize);
SoftTissue_subsection = getSubsection(softtissue, gm_surf_coord, SphereSize);
%eye_subsection = getSubsection(eye, gm_surf_coord, SphereSize);
CompactBone_subsection = getSubsection(bone_compact, gm_surf_coord, SphereSize);
SpongyBone_subsection = getSubsection(bone_spongy, gm_surf_coord, SphereSize);
blood_subsection = getSubsection(blood, gm_surf_coord, SphereSize);
%muscle_subsection = getSubsection(muscle, gm_surf_coord, SphereSize);

% get vector
if isfield(input,'Direction')
    if strcmp(input.BeginTissue,'GM')
        error('If a direction is given, the begin tissue should be scalp');
    end
    
    N = input.Direction;
    customOrientation = 1;
    
    gm_temporary = tissue_thickness(Triangulation2Intersect(gm_subsection, softtissue_surf_coord, N*-1));
    gm_surf_coord = gm_temporary{1, 1};
    if isempty(gm_surf_coord) 
        print('Given direction found no intersection with grey matter, inverting direction and retrying')
        gm_temporary = tissue_thickness(Triangulation2Intersect(gm_subsection, softtissue_surf_coord, N));
        gm_surf_coord = gm_temporary{1,1};
    end
else
    N = [(softtissue_surf_coord(1)-gm_surf_coord(1)),(softtissue_surf_coord(2)-gm_surf_coord(2)),(softtissue_surf_coord(3)-gm_surf_coord(3))];
    customOrientation = 0;
end

%% measure tissue thicknesses
gm_temporary = tissue_thickness(Triangulation2Intersect(gm_subsection, gm_surf_coord, N));
if gm_temporary{1, 1} == 0
else; gm_surf_coord = gm_temporary{1, 1}; end

intersect_SoftTissue = tissue_thickness(Triangulation2Intersect(SoftTissue_subsection, softtissue_surf_coord, N));
if intersect_SoftTissue{1, 1}  == 0
    intersect_SoftTissue{1, 1} = softtissue_surf_coord;
else; softtissue_surf_coord = intersect_SoftTissue{1, 1}; end

if norm(intersect_SoftTissue{1, 1}-intersect_SoftTissue{1, 2}) <= 0.0001
    intersect_SoftTissue{1, 2} = 0; end

% get grey matter thickness
[gm_thickness, wm_coord, gm_coord] = cortical_thickness(wm_subsection, csf_subsection, gm_surf_coord);
CORTICAL_Thickness(1) = gm_thickness;

% get intersections
if      isempty(csf_subsection) == 1;               intersect_CSF{1} = 0; intersect_CSF{2} = 0;
else;   intersect_CSF = tissue_thickness(Triangulation2Intersect(csf_subsection, gm_surf_coord, N)); end

if      isempty(SpongyBone_subsection) == 1;        intersect_SpongyBone{1} = 0; intersect_SpongyBone{2} = 0;
else;   intersect_SpongyBone = tissue_thickness(Triangulation2Intersect(SpongyBone_subsection, gm_surf_coord, N)); end

if      isempty(CompactBone_subsection) == 1;       intersect_CompactBone{1} = 0; intersect_CompactBone{2} = 0;
else;   intersect_CompactBone = tissue_thickness(Triangulation2Intersect(CompactBone_subsection, gm_surf_coord, N)); end

if      isempty(blood_subsection) == 1;             intersect_Blood{1} = 0; intersect_Blood{2} = 0;
else;   intersect_Blood = tissue_thickness(Triangulation2Intersect(blood_subsection, gm_surf_coord, N)); end

CSF_Missing = false;
if intersect_CSF{1, 1}  == 0
    if intersect_CSF{1, 2}  == 0
        if intersect_CompactBone{1, 2} == 0
            CSF_Missing = true;
        end; end; end

% check if all intersections were correctly obtained and if not, do so
% of note,  {1,1} is always to external intersection, {1,2} the internal
% intersection

if intersect_SoftTissue{1, 2} == 0
    intersect_SoftTissue{1, 2} = intersect_CompactBone{1, 1}; end

if intersect_CompactBone{1, 1} == 0
    intersect_CompactBone{1, 1} = intersect_SoftTissue{1, 2}; end

if intersect_CompactBone{1, 2} == 0
    intersect_CompactBone{1, 2} = intersect_CSF{1, 1}; end

if intersect_CSF{1, 1} == 0
    intersect_CSF{1, 1} = intersect_CompactBone{1, 2}; end

if intersect_CSF{1, 2} == 0
    intersect_CSF{1, 2} = gm_surf_coord; end

if CSF_Missing == true
    intersect_CSF{1, 2} = 0;
    intersect_CSF{1, 1} = 0;
    intersect_CompactBone{1,2} = gm_surf_coord;
end

if norm(intersect_CompactBone{1, 2} - intersect_CSF{1, 2}) <= 0.0001
    intersect_CompactBone{1, 2} = intersect_CSF{1, 1}; end

thickness_CSF = norm(intersect_CSF{1, 2}-intersect_CSF{1, 1});
thickness_SoftTissue = norm(intersect_SoftTissue{1, 2}-intersect_SoftTissue{1, 1});

thickness_bone = norm(intersect_CompactBone{1,1} - intersect_CompactBone{1, 2});
if intersect_SpongyBone{1,1} == 0   % option one: spongy bone doesn't exist
    thickness_CompactBone_internal = thickness_bone;
    thickness_CompactBone_external = 0;
    thickness_SpongyBone = 0;
else                                % option two: spongy bone
    thickness_CompactBone_internal = norm(intersect_CompactBone{1, 2} - intersect_SpongyBone{1, 2});
    thickness_CompactBone_external = norm(intersect_CompactBone{1, 1} - intersect_SpongyBone{1, 1});
    thickness_SpongyBone = norm(intersect_SpongyBone{1, 1} - intersect_SpongyBone{1, 2});
    thickness_bone_test = thickness_CompactBone_internal + thickness_CompactBone_external + thickness_SpongyBone;
    
    if thickness_bone - thickness_bone_test <= 0.0001
    else; error('Something went wrong when calculating bone thickness')
    end
end

if norm(intersect_Blood{1,1} - 0) == 0
else
    if intersect_Blood{1,2} == 0
        intersect_Blood{1,2} = intersect_CSF{1,1};
    end
end

thickness_blood = norm(intersect_Blood{1,1}-intersect_Blood{1,2});

if thickness_blood == 0
else
    if norm(intersect_CompactBone{1,2}-intersect_CSF{1,1}) <= 0.0001
        if norm(intersect_Blood{1,1}-intersect_CSF{1,1}) <= 0.0001
            thickness_blood = 0;
            thickness_CSF = 0;
        end
    end
end

ScalpToCortex = thickness_blood + thickness_bone + thickness_CSF + thickness_SoftTissue;
ScalpToCortex_Validation = norm(gm_surf_coord-softtissue_surf_coord);

%% handles irregularities in mesh related to CSF and blood
if thickness_blood > 0
    if abs((thickness_bone + thickness_CSF + thickness_SoftTissue) - ScalpToCortex_Validation) <= 0.0001
        ScalpToCortex = ScalpToCortex - thickness_blood;
        thickness_blood = 0;
    elseif abs((ScalpToCortex - thickness_blood) - ScalpToCortex_Validation) <= 0.0001
        ScalpToCortex = ScalpToCortex - thickness_blood;
        thickness_CSF = thickness_CSF - thickness_blood;
    end
end

if ((ScalpToCortex_Validation+thickness_CSF)- ScalpToCortex) <= 0.0001
    thickness_CSF = 0;
    ScalpToCortex = thickness_blood + thickness_bone + thickness_CSF + thickness_SoftTissue;
end

%% validation of results
if ScalpToCortex - ScalpToCortex_Validation <= 0.0001
else; error('SCD derived from individual distances doesnt equal SCD derived from gm and skin, something likely went wrong')
end

%% create output file
Output = table(CORTICAL_Thickness,thickness_CSF,thickness_blood,thickness_CompactBone_internal,thickness_SpongyBone,thickness_CompactBone_external,thickness_SoftTissue,ScalpToCortex);

%% plot MRI results
if input.PlotResults == 1 %plot results
    if customOrientation == 1
        factor = 25;
    else
        factor = 2.5;
    end
    quiver3(gm_surf_coord(1),gm_surf_coord(2),gm_surf_coord(3),(N(1)*factor),(N(2)*factor),(N(3)*factor),'Color','k'); hold on
    plot3(wm_coord(1),wm_coord(2),wm_coord(3),'o','Color','#ff0000','MarkerSize',15,'MarkerFaceColor','#FFFFFF'); hold on
    plot3(gm_coord(1),gm_coord(2),gm_coord(3),'o','Color','#ff0000','MarkerSize',15,'MarkerFaceColor','#FFFFFF'); hold on
    plot3(gm_surf_coord(1),gm_surf_coord(2),gm_surf_coord(3),'o','Color','#7B6979','MarkerSize',15,'MarkerFaceColor','#7B6979'); hold on
    for i = 1:2
        try plot3(intersect_CSF{1,i}(1,1),intersect_CSF{1,i}(1,2),intersect_CSF{1,i}(1,3),'o','Color','#6AA6F8','MarkerSize',15,'MarkerFaceColor','#6AA6F8'); hold on; end
        try plot3(intersect_Blood{1,i}(1,1),intersect_Blood{1,i}(1,2),intersect_Blood{1,i}(1,3),'o','Color','#002BFF','MarkerSize',15,'MarkerFaceColor','#002BFF'); hold on; end
        try plot3(intersect_SpongyBone{1,i}(1,1),intersect_SpongyBone{1,i}(1,2),intersect_SpongyBone{1,i}(1,3),'o','Color','#FF7F00','MarkerSize',15,'MarkerFaceColor','#FF7F00'); hold on; end
        try plot3(intersect_CompactBone{1,i}(1,1),intersect_CompactBone{1,i}(1,2),intersect_CompactBone{1,i}(1,3),'o','Color','#C3B789','MarkerSize',15,'MarkerFaceColor','#C3B789'); hold on; end
    end
    plot3(intersect_SoftTissue{1, 2}(1,1),intersect_SoftTissue{1, 2}(1,2),intersect_SoftTissue{1,2}(1,3),'o','Color','#C3B789','MarkerSize',15,'MarkerFaceColor','#C3B789'); hold on
    plot3(softtissue_surf_coord(1),softtissue_surf_coord(2),softtissue_surf_coord(3),'o','Color','#724D23','MarkerSize',15,'MarkerFaceColor','#724D23'); hold on
    v1=[gm_surf_coord;wm_coord];     v2=[gm_coord;wm_coord];
    plot3(v1(:,1),v1(:,2),v1(:,3),'k')
    plot3(v2(:,1),v2(:,2),v2(:,3),'k')
end

fields = {'wm_volume', 'gm_volume', 'csf_volume', 'blood_volume', 'bone_compact_volume', 'bone_spongy_volume', 'muscle_volume', 'skin_volume'};
volumes_idx = [1, 2, 3, 9, 7, 8, 10, 5];
for i = 1:length(fields)
    Output.(fields{i}) = volumes(volumes_idx(i));
end

if input.PlotResults == 1 %plot results
    trimesh(softtissue,'facecolor', '#A27440', 'edgecolor', '#724D23','FaceAlpha',0.1,'LineStyle','none'); hold on
    %trimesh(bone_compact,'facecolor', '#E5D7A1', 'edgecolor', '#C3B789','FaceAlpha',0.5,'LineStyle','none'); hold on
    %trimesh(bone_spongy,'facecolor', '#FFAE00', 'edgecolor', '#FF7F00','FaceAlpha',0.5,'LineStyle','none'); hold on
    %trimesh(blood,'facecolor', '#002BA7', 'edgecolor', '#002BFF','FaceAlpha',0.5,'LineStyle','none'); hold on
    %trimesh(csf,'facecolor', '#97DDFB', 'edgecolor', '#6AA6F8','FaceAlpha',0.5,'LineStyle','none'); hold on
    trimesh(gm,'facecolor', '#A3859C', 'edgecolor', '#7B6979','FaceAlpha',0.4,'LineStyle','none'); hold on
    trimesh(wm,'facecolor', '#F4F6FF', 'edgecolor', '#D3D4DC','FaceAlpha',1,'LineStyle','none'); hold on
end; toc
end
