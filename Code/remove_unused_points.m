function [new_points, new_connections] = remove_unused_points(points, connections)

n_connections = size(connections, 1);  % get number of connections
used_points = false(size(points, 1), 1);  % create array to track used points

for i = 1:n_connections % loop through connections and mark  used points
    used_points(connections(i, :)) = true;
end

used_indices = find(used_points);  % find used point indices
index_map = zeros(size(points, 1), 1);  % create mapping from old point indices to  new ones
index_map(used_indices) = 1:numel(used_indices);
new_connections = index_map(connections);  % remap the connections to use the new indices
new_points = points(used_indices, :);  % select used points

end