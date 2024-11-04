% Creates RDMs in .csv format from the RSA script.
function hcf_create_rdms(rdms_path, out_path, vars, rois, subjs)
    import rsa.rdm.*

    out_path = fullfile(out_path,'RDMs_out');
    out_subjs = fullfile(out_path,'subjs');
    out_flattened_path = fullfile(out_path,'flattened');
    subjs_sessions = fullfile(out_path,'subjs_sessions');
    out_subjs_averaged = fullfile(out_path,'subjs_averaged');
    out_flattened_sessions = fullfile(out_path,'flattened_sessions');

    if exist(out_path)~=7
        mkdir(out_path);
        mkdir(out_subjs);
        mkdir(out_flattened_path);
        mkdir(out_flattened_sessions);
        mkdir(subjs_sessions);
        mkdir(out_subjs_averaged);
    end

    % Load RDMs matrice
    load(rdms_path);
    total_rois = size(RDMs,1);
    total_subjects = size(RDMs,2);

    %% created flattened versions of the RDMs

    % Initialize a cell array to store the row names
    row_names = {};
    num_vars = length(vars);

    row_names = {}; % Initialize row names
    row_names_filled = false;
    % Iterate through each ROI
    for roi = 1:total_rois
        all_RDM_values = [];
        num_runs = size(RDMs(:, :,:), 3); % Assuming the third dimension is the number of runs

        % Loop through subjects to get RDM values for each pair
        for subj = 1:total_subjects
            % Initialize a variable to accumulate the RDMs for all runs
            accumulated_RDM = 0;
            subj_available_runs = 0;

            for run = 1:num_runs
                % Accumulate the RDMs for each run
                if ~isempty(RDMs(roi, subj, run).RDM)
                    subj_available_runs = subj_available_runs + 1;
                    accumulated_RDM = accumulated_RDM + RDMs(roi, subj, run).RDM;
                end
            end
            % Calculate the average RDM for the subject and ROI
            avg_RDM = accumulated_RDM / subj_available_runs;
            subj_RDM_values = [];
    
            % Extract upper triangular values excluding diagonal
            for i = 1:num_vars
                for j = i+1:num_vars
                    if ~row_names_filled
                        % Only generate row names once, during the first subject loop
                        row_names{end+1} = sprintf('%s_VS_%s', vars{i}, vars{j});
                    end
                    subj_RDM_values(end+1, 1) = avg_RDM(i, j);
                end
            end
            row_names_filled = true;
    
            % Concatenate RDM values for all subjects
            all_RDM_values = [all_RDM_values, subj_RDM_values];
        end
    
        % Create the final table with subjects as columns
        flattenedTable = array2table(all_RDM_values, 'VariableNames', subjs, 'RowNames', row_names);
    
        % Write the table to a CSV file
        writetable(flattenedTable, fullfile(out_flattened_path, [rois{roi}, '_flattened.csv']), 'WriteRowNames', true,'WriteVariableNames', true);
    end
    % Create directories for each run
    for run = 1:size(RDMs, 3)
        run_path = fullfile(out_flattened_sessions, ['RUN_' num2str(run)]);
        if ~exist(run_path, 'dir')
            mkdir(run_path);
        end
    end
    
    row_names = {}; % Initialize row names for the variables (only need to generate once per ROI)
    row_names_filled = false;

    % Iterate through each ROI
    for roi = 1:total_rois
        % Loop through each run
        for run = 1:size(RDMs, 3)
            % Path for the current run
            run_path = fullfile(out_flattened_sessions, ['RUN_' num2str(run)]);
            
            % Initialize an empty table to hold the RDM values for all subjects
            all_subjects_RDM = [];
            missing_subjects = {};

            % Loop through subjects to get RDM values for each pair
            for subj = 1:total_subjects
                % Extract the RDM for the current run and subject
                subj_RDM = RDMs(roi, subj, run).RDM;
                if isempty(subj_RDM)
                    missing_subjects{end+1} = subjs{subj};
                    continue;
                end
                subj_RDM_values = [];
                
                % Extract upper triangular values excluding diagonal
                for i = 1:num_vars
                    for j = i+1:num_vars
                        subj_RDM_values(end+1, 1) = subj_RDM(i, j);
                    end
                end
                
                % Append the current subject's RDM values as a column to the table
                all_subjects_RDM = [all_subjects_RDM, subj_RDM_values];
            end
            
            % Create the final table with all subjects as columns
            flattenedTable = array2table(all_subjects_RDM, 'VariableNames', setdiff(subjs,missing_subjects), 'RowNames', row_names);
            
            % Write the table to a CSV file (one file per ROI for all subjects)
            writetable(flattenedTable, fullfile(run_path, [rois{roi}, '_flattened.csv']), 'WriteRowNames', true, 'WriteVariableNames', true);
        end
    end

    %% Create RDMs seperately for every run

    for run = 1:size(RDMs,3)
        run_path = fullfile(subjs_sessions,['RUN_' num2str(run)]);
        if ~exist(run_path)~=7 
            mkdir(run_path);
        end
    end
           
    for roi = 1:total_rois
        roi_RDM = RDMs(roi,:,:);
        for subj = 1:total_subjects
            subj_RDM = RDMs(roi,subj,:);
            for run = 1:size(subj_RDM,3)
                subj_out_path = fullfile(subjs_sessions,['RUN_' num2str(run)],subjs{subj});
                if ~isfolder(subj_out_path)
                    mkdir(subj_out_path);
                end
                subj_RDM = RDMs(roi,subj,run);
                if ~isempty(subj_RDM.RDM)
                    T = array2table(subj_RDM.RDM,'VariableNames',vars,'RowNames',vars);
                    writetable(T,fullfile(subj_out_path, [rois{roi}, '.csv']),'WriteRowNames',true,'WriteVariableNames',true); 
                end
            end
        end
    end

   %% Create RDMs averaged for all sessions,

    for roi = 1:total_rois
        num_runs = size(RDMs(:, :,:), 3); % Assuming the third dimension is the number of runs
        ROI_accumulated_RDM = 0;

        for subj = 1:total_subjects
            % Initialize a variable to accumulate the RDMs for all runs
            accumulated_RDM = 0;
            subj_available_runs = 0;
            
            for run = 1:num_runs
                % Accumulate the RDMs for each run
                if ~isempty(RDMs(roi, subj, run).RDM)
                    subj_available_runs = subj_available_runs + 1;
                    accumulated_RDM = accumulated_RDM + RDMs(roi, subj, run).RDM;
                end
            end
            
            % Calculate the average RDM for the subject and ROI
            avg_RDM = accumulated_RDM / subj_available_runs;
            ROI_accumulated_RDM = ROI_accumulated_RDM + avg_RDM;
            
            % Create the output path for the subject
            subj_out_path = fullfile(out_subjs, subjs{subj});
            if ~isfolder(subj_out_path)
                mkdir(subj_out_path);
            end
            
            % Convert the average RDM to a table and write to a CSV file
            T = array2table(avg_RDM, 'VariableNames', vars, 'RowNames', vars);
            writetable(T, fullfile(subj_out_path, [rois{roi}, '.csv']), 'WriteRowNames', true, 'WriteVariableNames', true);
        end
        
        ROI_avg_RDM = ROI_accumulated_RDM / total_subjects;
        T = array2table(ROI_avg_RDM, 'VariableNames', vars, 'RowNames', vars);
        writetable(T, fullfile(out_subjs_averaged, [rois{roi}, '.csv']), 'WriteRowNames', true, 'WriteVariableNames', true);
    end
end
