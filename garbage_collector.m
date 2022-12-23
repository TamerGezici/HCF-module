% Excludes garbage collection for specific modules. The exclude_modules
% parameter receives a cell array of modules to exclude from collection.
function garbage_collector(aap,exclude_modules,permanence_threshold)
    current_module_list = {aap.tasklist.main.module.name}';
    exclude_module_ids = [];
    for i=1:size(exclude_modules,1)
        id = find(strcmp(current_module_list,exclude_modules{i}));
        exclude_module_ids(end+1) = id;
    end
    modules_to_scan = 1:size(current_module_list,1);
    modules_to_scan(modules_to_scan == exclude_module_ids) = [];
    %aas_garbagecollection(aap, 0, modules_to_scan, 0);
end

