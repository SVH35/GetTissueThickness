function Output_tt = tissue_thickness(tissue,WM)


[~,index] = sortrows([tissue.intersect].'); tissue = tissue(index(end:-1:1)); clear index
output_T = struct2table(tissue);


if sum(output_T{:,1}) == 1
    Output_CSF{1,1} = tissue(1);
    intersectpoint = tissue(1).xcoor;
else
    if nargin == 2
        tissue = tissue(1:sum(output_T{:,1}));
        [~,index] = sortrows([tissue.t].'); tissue = tissue(index(1:1:length(index))); clear index
        Output_CSF{1,1} = tissue(1);
        intersectpoint = tissue(1).xcoor;
    else
        tissue = tissue(1:sum(output_T{:,1}));
        [~,index] = sortrows([tissue.t].'); tissue = tissue(index(end:-1:1)); clear index
        Output_CSF{1,1} = tissue(1);
        intersectpoint = tissue(1).xcoor;
    end
end


Output_tt{1} = Output_CSF{1,1};
Output_tt{2} = intersectpoint;

end