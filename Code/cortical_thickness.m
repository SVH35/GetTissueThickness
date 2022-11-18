function [Output] = cortical_thickness(wm, gm, coords1)

%% distance 1: GM to WM
% calculated minimal distance from GM coordinate to white matter
coords2 = wm.Points;
parfor i = 1:length(coords2)
    EuclideanDistance(i,1) = (coords1(1) - coords2(i,1))^2 + (coords1(2) - coords2(i,2))^2 + (coords1(3) - coords2(i,3))^2; end

counter = 0;
for i = 1:length(EuclideanDistance)
    counter = counter + 1; EuclideanDistance(i,2) = counter; end
EuclideanDistance = sortrows(EuclideanDistance,1,'ascend');
triangle_points1 = EuclideanDistance(1:3,2);

for i = 1:3
    triangle_coords1(i,:) = coords2(triangle_points1(i),:); end

[distance1, WM_point] = pointTriangleDistance(triangle_coords1,coords1);
clear EuclideanDistance
%% distance 2: WM to GM
% calculated minimal distance from obtained WM coordinate to grey matter
coords4 = gm.Points;
parfor i = 1:length(coords4)
    EuclideanDistance(i,1) = (WM_point(1) - coords4(i,1))^2 + (WM_point(2) - coords4(i,2))^2 + (WM_point(3) - coords4(i,3))^2; end

counter = 0;
for i = 1:length(EuclideanDistance)
    counter = counter + 1; EuclideanDistance(i,2) = counter; end
EuclideanDistance = sortrows(EuclideanDistance,1,'ascend');
triangle_points2 = EuclideanDistance(1:3,2);

for i = 1:3
    triangle_coords2(i,:) = coords4(triangle_points2(i),:); end
[distance2, GM_point] = pointTriangleDistance(triangle_coords2,WM_point);

%% average distance
Output = (distance1 + distance2)/2;
end