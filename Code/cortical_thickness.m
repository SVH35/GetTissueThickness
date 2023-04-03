function [Output, WM_point, GM_point] = cortical_thickness(wm, csf, coords1)

%% distance 1: GM to WM
% calculated minimal distance from GM coordinate to white matter
EuclideanDistance = sum((coords1 - wm.Points) .^ 2, 2);
EuclideanDistance(:, 2) = (1:length(EuclideanDistance))';
EuclideanDistance = sortrows(EuclideanDistance,1,'ascend');
triangle_points1 = EuclideanDistance(1:3,2);
triangle_coords1 = wm.Points(triangle_points1(1:3), :);
[distance1, WM_point] = pointTriangleDistance(triangle_coords1,coords1);
clear EuclideanDistance

%% distance 2: WM to GM
% calculated minimal distance from obtained WM coordinate to grey matter
EuclideanDistance = sum((WM_point - csf.Points) .^ 2, 2);
EuclideanDistance(:, 2) = (1:length(EuclideanDistance))';
EuclideanDistance = sortrows(EuclideanDistance,1,'ascend');
triangle_points2 = EuclideanDistance(1:3,2);
triangle_coords2 = csf.Points(triangle_points2(1:3), :);
[distance2, GM_point] = pointTriangleDistance(triangle_coords2,WM_point);

%% average distance
Output = (distance1 + distance2)/2;
end