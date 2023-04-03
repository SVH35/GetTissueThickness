function [triangulation_out] = getSubsection(triangulationStructure, referenceCoordinate, maxDistance)

% Extract information from the triangulation structure
pts = triangulationStructure.Points;
cl = triangulationStructure.ConnectivityList;

counter = 0;
for i = 1:length(cl)
    triangle = pts(cl(i,:),1:3);
    triangle_center = mean(triangle,1);
    if norm(triangle_center - referenceCoordinate) > maxDistance
    else
        counter = counter + 1;
        cl_out(counter,:) = cl(i,:);
    end
end

% Update the triangulation
if exist('cl_out','var')
    if length(cl_out) == 3
        triangulation_out = [];
    else
        [final_pts,final_cl] = remove_unused_points(pts,cl_out);
        triangulation_out = triangulation(final_cl,final_pts);
    end
else
    triangulation_out = [];
end
end
