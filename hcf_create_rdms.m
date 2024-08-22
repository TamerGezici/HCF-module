% Creates RDMs in .csv format from the RSA script.
function hcf_create_rdms(rdms_path, out_path, vars, rois, subjs)
    import rsa.rdm.*

    out_path = fullfile(out_path,'RDMs_out');
    out_subjs = fullfile(out_path,'subjs');
    out_subjs_averaged = fullfile(out_path,'subjs_averaged');
    out_flattened_path = fullfile(out_path,'flattened');

    if exist(out_path)~=7
        mkdir(out_path);
        mkdir(out_subjs);
        mkdir(out_subjs_averaged);
        mkdir(out_flattened_path);
    end

    % Load RDMs matrice
    load(rdms_path);

    averaged_RDM = averageRDMs_subjectSession(RDMs,'subject','session');
    
    total_rois = size(RDMs,1);
    for roi=1:total_rois
        roi_RDM = averaged_RDM(roi).RDM;
        roi_out_path = fullfile(out_path,'subjs_averaged');
        T = array2table(roi_RDM,'VariableNames',vars,'RowNames',vars);
        writetable(T,fullfile(roi_out_path, [rois{roi}, '.csv']),'WriteRowNames',true,'WriteVariableNames',true);
    end

    subj_averaged_RDM = averageRDMs_subjectSession(RDMs,'session');

    total_subjects = size(subj_averaged_RDM,2);
    for subj = 1:total_subjects
        subj_out_path = fullfile(out_path,'subjs',subjs{subj});
        if exist(subj_out_path)~=7
            mkdir(subj_out_path);
        end
        for roi = 1:total_rois
            subj_RDM = subj_averaged_RDM(roi,subj).RDM;
            T = array2table(subj_RDM,'VariableNames',vars,'RowNames',vars);
            writetable(T,fullfile(subj_out_path, [rois{roi}, '.csv']),'WriteRowNames',true,'WriteVariableNames',true);
                    
        end
    end

    % Initialize a cell array to store the row names
    row_names = {};
    num_vars = length(vars);

    % Iterate through each ROI
    for roi = 1:total_rois
        all_RDM_values = [];

        % Loop through subjects to get RDM values for each pair
        for subj = 1:total_subjects
            subj_RDM = subj_averaged_RDM(roi, subj).RDM;
            subj_RDM_values = [];

            % Extract upper triangular values excluding diagonal
            for i = 1:num_vars
                for j = i+1:num_vars
                    if subj == 1 && roi == 1
                        % Only generate row names once, during the first subject loop
                        row_names{end+1} = sprintf('%s_VS_%s', vars{i}, vars{j});
                    end
                    subj_RDM_values(end+1, 1) = subj_RDM(i, j);
                end
            end

            % Concatenate RDM values for all subjects
            all_RDM_values = [all_RDM_values, subj_RDM_values];
        end

        % Create the final table with subjects as columns
        flattenedTable = array2table(all_RDM_values, 'VariableNames', subjs, 'RowNames', row_names);

        % Write the table to a CSV file
        writetable(flattenedTable, fullfile(out_flattened_path, [rois{roi}, '_flattened.csv']), 'WriteRowNames', true);
    end
end
