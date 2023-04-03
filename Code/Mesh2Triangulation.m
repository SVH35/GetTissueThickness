function [wm gm csf scalp eye bone_compact bone_spongy blood muscle volumes] = MeshToTriangulation(m)

%% MeshToTriangulation
% this script creates a triangulation matrix per tetrahedron

% structures: 1=wm, 2=gm, 3=csf, 5=scalp, 6=eye, 7=bone_compact, 8=bone_spongy, 9=blood, 10=muscle];

for i = 1:10
    if i == 4
    else
        TetraMesh(i).data = mesh_extract_regions(m, 'region_idx', i);
    end
end

for i = 1:length(TetraMesh)
    if i == 4
    else
        TetraMesh2Use = TetraMesh(1,i).data;
        TetraMesh2Use_Points = TetraMesh2Use.nodes;
        TetraMesh2Use_ConnectivityList = [TetraMesh2Use.tetrahedra(:,[1 2 3]);TetraMesh2Use.tetrahedra(:,[1 2 4]);TetraMesh2Use.tetrahedra(:,[1 3 4]);TetraMesh2Use.tetrahedra(:,[2 3 4])];
        TetraMesh2Use_ConnectivityList = sort(TetraMesh2Use_ConnectivityList,2);
        TetraMesh2Use_ConnectivityList = sortrows(TetraMesh2Use_ConnectivityList);
        duploc = find(all(diff(TetraMesh2Use_ConnectivityList) == 0,2));
        TetraMesh2Use_ConnectivityList([duploc;duploc + 1],:) = [];
        M = max(TetraMesh2Use_ConnectivityList,[], 'all');
        TetraMesh2Use_Points = TetraMesh2Use_Points(1:M,:); warning('off');
        TriMesh = triangulation(TetraMesh2Use_ConnectivityList,TetraMesh2Use_Points); warning('on')
        volumes(1,i) = sum(mesh_get_tetrahedron_sizes(TetraMesh2Use));
        
        if i == 1; wm = TriMesh; 
        elseif i == 2 ; gm = TriMesh;
        elseif i == 3; csf = TriMesh;
        elseif i == 5; scalp = TriMesh;
        elseif i == 6; eye = TriMesh;
        elseif i == 7; bone_compact = TriMesh;
        elseif i == 8; bone_spongy = TriMesh;
        elseif i == 9; blood = TriMesh;
        elseif i == 10; muscle = TriMesh;
        end
    end
end



end

