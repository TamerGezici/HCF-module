function [outputArg1] = estimate_rois(subjects,first_level_dir,smoothened_dir,task_filter,roi_dir,events_dir_name)
    mbd = fullfile(spm('dir'),'toolbox','marsbar');
    spm;
    marsbar on
    if exist(mbd)==7
        addpath(mbd); 
    end
    
    roi_dir = fullfile(pwd,'ROI',events_dir_name,'roi_list');
    resdir = fullfile(pwd,'ROI',events_dir_name,'results');
    if exist(resdir)~=7
        mkdir(resdir);
        mkdir(fullfile(resdir,'csv'));
    end
    
    roi_summary_function = 'mean'; % what function marsbar uses to summarise
    %roi data over voxels. options= 'mean', 'median', 'eig1', 'wtmean'
    
    modeldur=1;

    % results structure
    res = struct('roi','','subs','','beta',[],...
        'percent',[],'dims','roi, sub, event');
     
    nsubs = length(subjects);
    % Get ROIs ****************************************************************
    rois = spm_select('List',roi_dir,'roi.mat$');
    files = dir(fullfile(roi_dir,'*.mat'));
    roi_names = {files.name};
    nrois = size(rois,1);
    roi_short = rois;
    res.rois = rois;
    rois = [repmat([roi_dir filesep],nrois,1) rois];
    all_subject_results = {};
    subject_session_counts = table();
    
    for i = 1:nrois
        nom = roi_short(i,:);
        nom = deblank(nom);
        l = length(nom);
        nom = nom(1:4);
        roishort{i}=nom;
    end

    for subj_no=1:nsubs
        clear SPM f
        csub = subjects{subj_no};
        desfile = fullfile(first_level_dir,csub,'stats','SPM.mat');
        SPM = load(desfile);
        D = mardo(SPM);
        current_sub_result_table = table();        
        % Loop through ROIs
        for r=1:nrois
            croi = deblank(rois(r,:));
            disp([csub croi]);
            R = maroi(croi); % load roi into a marsbar maroi object structure
            Y = get_marsy(R,D,roi_summary_function); % get summarised time course for this ROI
            E = estimate(D,Y); % estimate design based on this summarised time course
            SPM = des_struct(E); %unpack marsbar design structure
            subject_session_counts(csub,'count') = {size(SPM.Sess,2)};
            smeans = SPM.betas(SPM.xX.iB); % session means - these are used for calculating percent signal change
            res.beta{r,subj_no} = SPM.betas(SPM.xX.iC);
            beta_estimates = SPM.betas(SPM.xX.iC)';% load beta values for effects of interest into results structure
            current_roi_name = strrep({roi_names{r}},'.mat','');
            regressor_names = strrep(SPM.xX.name(SPM.xX.iC),'*bf(1)','');       
            for beta_number=1:size(beta_estimates,2)
                current_sub_result_table(current_roi_name{1},regressor_names{beta_number}) = {beta_estimates(beta_number)};
            end
            writetable(current_sub_result_table,fullfile(resdir,'csv',[csub '.csv']));
            
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
    end
    save(resmat,'res');
    
    for subject = 1:size(subjects,2)
        subj_name = subjects{subject};    
        subj_table = all_subject_results{subject};
        n_sessions = subject_session_counts{subj_name,'count'};
        for session = 1:n_sessions
            for regressor = 1:size(regressor_names,2)
                stripped = strrep(SPM.xX.name(SPM.xX.iC),'*bf(1)','');    
            end
        end
    end
    
end