function closest = findClosest3DCoord(list, coord)
    distances = sqrt((list(:,1) - coord(1)).^2 + (list(:,2) - coord(2)).^2 + (list(:,3) - coord(3)).^2);
    [~, index] = min(distances);
    closest = list(index,:);
end