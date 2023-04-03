% this function takes an MRI scan (256,256,256 uint16, typically present in
% simnibs m2m folder) and creates a mask of the coordinates used by GTT to
% measure tissue thickness. It saves a visual output (mask) to MRI scan folder
% to interpret the accuracy of results.

function MRI_MASK(Type, MRI_path, gm_i, csf_i, spongybone_i, compactbone_i, softtissue_i, blood_i, centre)

if Type == 'T1'
    if exist('GTT_T1.nii','var')
        MRI_path = strcat(MRI_path,'\GTT_T1');
    else; MRI_path = strcat(MRI_path,'\T1.nii.gz');
    end
else
    if exist('GTT_T2.nii','var')
        MRI_path = strcat(MRI_path,'\GTT_T2');
    else; MRI_path = strcat(MRI_path,'\T2.nii.gz');
    end
end

MRI = niftiread(MRI_path);
MRI_CLONE = MRI;

s.coordlist(1,:) = round(gm_i);
s.coordlist(2,:) = round(csf_i);
s.coordlist(3,:) = round(spongybone_i);
s.coordlist(4,:) = round(compactbone_i);
s.coordlist(5,:) = round(softtissue_i);
s.coordlist(6,:) = round(blood_i);

s.isovalues = 20000:6000:50000;


%% create clone
%MRI_CLONE(1:256,1:256,1:256) = 0;

%% Create mask of GTT used coords
for tissue_i = 1:6
    if s.coordlist(tissue_i) == 0
    else
        loop_coord = s.coordlist(tissue_i,:) + centre; % changes coord to matlab system
        counter = 0;
        
        for i = 1:3
            counter = counter + 4;
            if i == 1
                COI_LIST(counter,:) = loop_coord + [1,0,0];
                COI_LIST(counter+1,:) = loop_coord + [-1,0,0];
                COI_LIST(counter+2,:) = loop_coord + [2,0,0];
                COI_LIST(counter+3,:) = loop_coord + [-2,0,0];
            elseif i == 2
                COI_LIST(counter,:) = loop_coord + [0,1,0];
                COI_LIST(counter+1,:) = loop_coord + [0,-1,0];
                COI_LIST(counter+2,:) = loop_coord + [0,2,0];
                COI_LIST(counter+3,:) = loop_coord + [0,-2,0];
            elseif i == 3
                COI_LIST(counter,:) = loop_coord + [0,0,1];
                COI_LIST(counter+1,:) = loop_coord + [0,0,-1];
                COI_LIST(counter+2,:) = loop_coord + [0,0,2];
                COI_LIST(counter+3,:) = loop_coord + [0,0,-2];
            end
        end
        
        COI_LIST(1:3,:) = [];
        
        for i = 1:length(COI_LIST)
            MRI(COI_LIST(i,1),COI_LIST(i,2),COI_LIST(i,3)) = s.isovalues(1,tissue_i);
            MRI_CLONE(COI_LIST(i,1),COI_LIST(i,2),COI_LIST(i,3)) = s.isovalues(1,tissue_i);
        end
    end
end

if Type == 'T1'
niftiwrite(MRI_CLONE,'GTT_T1')
else
niftiwrite(MRI_CLONE,'GTT_T2')
end

end
