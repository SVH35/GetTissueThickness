function out = Triangulation2Intersect(triangulationStructure, m1coord_mesh, N)

vertexMatrix = zeros(height(triangulationStructure.ConnectivityList),3,3);
pts = triangulationStructure.Points;
cl = triangulationStructure.ConnectivityList;

if contains(struct2array(ver), 'Parallel Computing Toolbox') == 1
    parfor i = 1:length(cl)
        vertexMatrix(i,:,:) = pts(cl(i,:),1:3);
    end
else
    for i = 1:length(cl)
        vertexMatrix(i,:,:) = pts(cl(i,:),1:3);
    end
end

if contains(struct2array(ver), 'Parallel Computing Toolbox') == 1
    parfor vertexCount = 1:length(vertexMatrix)
        [intersect, t, u, v, xcoor] = TriangleRayIntersection(m1coord_mesh,N,squeeze(vertexMatrix(vertexCount,:,:)));
        out(vertexCount).intersect = intersect;
        out(vertexCount).t = t;
        out(vertexCount).u = u;
        out(vertexCount).v = v;
        out(vertexCount).xcoor = xcoor;
    end
else
    for vertexCount = 1:length(vertexMatrix)
        [intersect, t, u, v, xcoor] = TriangleRayIntersection(m1coord_mesh,N,squeeze(vertexMatrix(vertexCount,:,:)));
        out(vertexCount).intersect = intersect;
        out(vertexCount).t = t;
        out(vertexCount).u = u;
        out(vertexCount).v = v;
        out(vertexCount).xcoor = xcoor;
    end
    
    
end