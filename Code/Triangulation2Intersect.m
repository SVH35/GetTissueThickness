function out = Triangulation2Intersect(triangulationStructure, m1coord_mesh, N)

vertexMatrix = zeros(height(triangulationStructure.ConnectivityList),3,3);

parfor i = 1:length(triangulationStructure.ConnectivityList)
    vertexMatrix(i,:,:) = triangulationStructure.Points(triangulationStructure.ConnectivityList(i,:),1:3);
end


for vertexCount = 1:length(vertexMatrix)
    [intersect, t, u, v, xcoor] = TriangleRayIntersection(m1coord_mesh,N,squeeze(vertexMatrix(vertexCount,:,:)));
    out(vertexCount).intersect = intersect;
    out(vertexCount).t = t;
    out(vertexCount).u = u;
    out(vertexCount).v = v;
    out(vertexCount).xcoor = xcoor;
end


end