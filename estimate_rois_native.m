function [group_level_results] = estimate_rois_native(subjects,first_level_dir,smoothened_dir,task_filter,roi_dir,events_dir_name,work_dir)
    % Leave task filter empty
    mbd = fullfile(spm('dir'),'toolbox','marsbar');
    spm;
    marsbar on;
    close all;
    if exist(mbd)==7
        addpath(mbd); 
    end
    
    resdir = fullfile(work_dir,'ROI_results',events_dir_name);
    if exist(resdir)~=7
        mkdir(resdir);
        mkdir(fullfile(resdir,'per_subj'));
        mkdir(fullfile(resdir,'session_averages'));
    end
    
    roi_summary_function = 'mean'; % what function marsbar uses to summarise
    %roi data over voxels. options= 'mean', 'median', 'eig1', 'wtmean'
    
    modeldur=1;

    % results structure
    res = struct('roi','','subs','','beta',[],...
        'percent',[],'dims','roi, sub, event');
     
    nsubs = length(subjects);
    
    all_subject_results = {};
    subject_session_counts = table();

    for subj_no=1:nsubs
        clear SPM f
        csub = subjects{subj_no};
        desfile = fullfile(first_level_dir,csub,'stats','SPM.mat');
        %desfile = fullfile(first_level_dir,csub,'SPM.mat');
        D = mardo(desfile);
        %D = cd_images(D, fullfile(smoothened_dir,csub));
        save_spm(D);
        current_sub_result_table = table();

        roi_name = spm_select('List',fullfile(roi_dir,csub),'.mat$');
        files = dir(fullfile(roi_dir,csub,'*.mat'));
        roi_names = {files.name};
        clean_roi_names = strrep(roi_names,'.mat','');
        nrois = size(roi_names,2);
        res.rois = roi_name;      


        % Loop through ROIs
        for r=1:nrois
            croi = roi_names{r};
            disp([csub croi]);
            roi_path = fullfile(roi_dir,csub,croi);
            R = maroi(roi_path); % load roi into a marsbar maroi object structure
            Y = get_marsy(R,D,roi_summary_function); % get summarised time course for this ROI
            E = estimate(D,Y); % estimate design based on this summarised time course
            SPM = des_struct(E); %unpack marsbar design structure
            subject_session_counts(csub,'count') = {size(SPM.Sess,2)};
            smeans = SPM.betas(SPM.xX.iB); % session means - these are used for calculating percent signal change
            res.beta{r,subj_no} = SPM.betas(SPM.xX.iC);% load beta values for effects of interest into results structure
            beta_estimates = SPM.betas(SPM.xX.iC)';
            current_roi_name = strrep({roi_names{r}},'.mat','');

            %% Rename regressors (remove that annoying bf(1) text)
            spm_regressors = SPM.xX.name(SPM.xX.iC);
            single_bf = true;
            for i = 1:length(spm_regressors)
                if contains(spm_regressors{i}, '*bf(2)')
                    single_bf = false;
                    break;
                end
            end
            regressor_names = SPM.xX.name(SPM.xX.iC);
            if single_bf
                regressor_names = strrep(regressor_names,'*bf(1)','');   
            end
            if ~single_bf
                pattern = '\*bf\((\d+)\)';
                % Iterate through the cell array and replace the matched pattern
                for i = 1:length(regressor_names)
                    newElement = regexprep(regressor_names{i}, pattern, '_$1');
                    regressor_names{i} = newElement;
                end
            end

            for beta_number=1:size(beta_estimates,2)
                current_sub_result_table(current_roi_name{1},regressor_names{beta_number}) = {beta_estimates(beta_number)};
            end

            writetable(current_sub_result_table,fullfile(resdir,'per_subj',[csub '.csv']),'WriteRowNames',true);
            
            % calculate percent signal change for each beta value, marsbar
            % style
            %         i=0;
            %         res.percent{r,s}=[];
            %         for sess = 1:size(SPM.Sess,2)
            %             for ev = 1:size(SPM.Sess(sess).col,2)
            %                 cc = SPM.Sess(sess).col(ev);
            %                 cb = SPM.betas(cc);
            %
            %                 if ev<=length(SPM.Sess(sess).U)
            %                     if modeldur
            %                         evdur = mean(SPM.Sess(sess).U(ev).dur);
            %                     else
            %                         evdur=1;
            %                     end
            %
            %                     if evdur==0
            %                         sf = zeros(SPM.xBF.T,1);
            %                         sf(1) = SPM.xBF.T;
            %                     else
            %                         sf = ones(round(evdur/SPM.xBF.dt), 1);
            %                     end
            %
            %                     X = [];
            %                     for b = 1:size(SPM.xBF.bf,2)
            %                         X = [X conv(sf, SPM.xBF.bf(:,b))];
            %                     end
            %
            %                     Yh = X*cb;
            %                     [d i] = max(abs(Yh), [], 1);
            %                     d = Yh(i);
            %                 else
            %                     d=cb;
            %                 end
            %
            %                 res.percent{r,s}(end+1)= 100*(d/smeans(sess));
            %             end
            % end
        end
        all_subject_results(subj_no) = {current_sub_result_table};
        save(fullfile(resdir,'all_subject_results'),'all_subject_results');
        save(fullfile(resdir,'results'),'res');
    end
    

    %% Averages all sessions for each subject and outputs them seperately. Removes the annoying sn(1)  text
    all_subjects_cell = {}; % put all subjects' table in a cell array
    for subject = 1:size(subjects,2)
        subj_name = subjects{subject};    
        subj_table = all_subject_results{subject};
        combined_subj_table = table();
        n_sessions = subject_session_counts{subj_name,'count'};
        for regressor = 1:size(regressor_names,2)
            reg_index = strfind(regressor_names{regressor},' '); 
            reg_name = regressor_names{regressor}(reg_index+1:end); % find our general regressor name, disregarding session number
            selected_sessions = {}; % which sessions to select?
            for session = 1:n_sessions
                sess_reg = ['Sn(' num2str(session) ')' ' ' reg_name]; % find the regressor for that specific session
                if ismember(sess_reg,subj_table.Properties.VariableNames)
                    selected_sessions{end+1} = sess_reg; % put them in a cell array (this is to find values for this specific regressor for all sessions)
                end
            end
            averages = mean(subj_table{:,selected_sessions},2); % get an average of all sessions for this regressor
            for roi = 1:size(clean_roi_names,2)
                combined_subj_table(clean_roi_names{roi},reg_name) = {averages(roi)};
            end
        end
        all_subjects_cell{subject} = combined_subj_table;
        writetable(combined_subj_table,fullfile(resdir,'session_averages',[subj_name '.csv']),'WriteRowNames',true);
    end

    %% Generates second level results
    all_subjects_table = array2table(zeros(size(all_subjects_cell{1}.Properties.RowNames,1),...
    size(all_subjects_cell{1}.Properties.VariableNames,2)),...
    "RowNames",all_subjects_cell{1}.Properties.RowNames,...
    "VariableNames",all_subjects_cell{1}.Properties.VariableNames);
    for subject = 1:size(all_subjects_cell,2)
        curr_table = all_subjects_cell{subject};
        columns = all_subjects_cell{1}.Properties.VariableNames;
        rows = all_subjects_cell{1}.Properties.RowNames;
        for row=1:size(rows,1)
            for col=1:size(columns,2)
                all_subjects_table(row,col) = {all_subjects_table{rows{row},col} + curr_table{rows{row},col}};
            end
        end
    end
    group_level_results = array2table(table2array(all_subjects_table)/size(all_subjects_cell,2), 'variablenames', all_subjects_table.Properties.VariableNames, 'rownames', regexprep(all_subjects_table.Properties.RowNames, 'sub-\d+', ''));
    writetable(group_level_results,fullfile(resdir,'group_level_results.csv'),'WriteRowNames',true);

    %% Combine all subjects' results into a single CSV file
    % Define the directory containing your CSV files
    directory = fullfile(resdir,'session_averages');

    % Get a list of all CSV files in the directory
    files = dir(fullfile(directory, '*.csv'));

    % Initialize combined data
    combinedData = [];

    % Loop through each CSV file
    for i = 1:length(files)
        % Read the CSV file
        filename = fullfile(directory, files(i).name);
        data = readtable(filename);
        
        % Append subject identifier to each ROI
        subjectID = repmat({strtok(files(i).name, '.')}, height(data), 1);
        data.Subject = subjectID;
        
        % Combine data
        combinedData = [combinedData; data];
    end
    
    % Rename the "Row" column to "ROI"
    combinedData = renamevars(combinedData, 'Row', 'ROI');

    % Rearrange columns to make "subject" the first column
    subjectCol = combinedData(:, {'Subject'});
    combinedData = combinedData(:, [size(combinedData, 2), 1:(size(combinedData, 2) - 1)]);
    combinedData.ROI = regexprep(combinedData.ROI, 'sub-\d+', '');
    % Write combined data to a single CSV file
    writetable(combinedData, fullfile(resdir,'all_subjects_combined.csv'));
end