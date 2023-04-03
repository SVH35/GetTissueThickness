function Output_tt = tissue_thickness(tissue)

[~,index] = sortrows([tissue.intersect].'); tissue = tissue(index(end:-1:1)); clear index
output_T = struct2table(tissue);

Output_tt{1} = 0;
Output_tt{2} = 0;

if sum(output_T{:,1}) == 0 %no intersection with tissue
    
elseif sum(output_T{:,1}) == 1 %only one intersection
    Output_tt{1} = tissue(1).xcoor;
    
else %multiple intersections, takes first and last intersection
    tissue = tissue(1:sum(output_T{:,1}));
    [~,index] = sortrows([tissue.t].'); tissue = tissue(index(end:-1:1)); clear index
    Output_tt{1} = tissue(1).xcoor;
    Output_tt{2} = tissue(end).xcoor;
    if Output_tt{1} == Output_tt{2}
        Output_tt{2} = 0;
    else; end 
end
end