%% Perform second level searchlight analysis using SPM on data from TDT.

function hcf_searchlight_single_subject(subjectsDir, smoothingFWHM, glm_dir)
    % Get a list of subject folders
    subjectFolders = dir(subjectsDir);
    subjectFolders = subjectFolders([subjectFolders.isdir]);
    subjectFolders = subjectFolders(~ismember({subjectFolders.name}, {'.', '..'}));

    % Initialize a cell array to store paths to smoothed images
    smoothedImages = cell(numel(subjectFolders), 1);
    pattern = '^res_accuracy_minus_chance_set\d+\.nii$';

    for i = 1:numel(subjectFolders)
        % Define subject directory
        subjectDir = fullfile(subjectsDir, subjectFolders(i).name);
    
        % Define pattern to match accuracy files
        accuracyFile = spm_select('FPList', subjectDir, pattern);
    
        % Check if accuracyFile is found
        if isempty(accuracyFile)
            warning('No accuracy file found for subject %s.', subjectFolders(i).name);
            continue;
        end
    
        % Smooth the accuracy map
        matlabbatch = [];
        matlabbatch{1}.spm.spatial.smooth.data = cellstr(accuracyFile); % Convert to cell array
        matlabbatch{1}.spm.spatial.smooth.fwhm = smoothingFWHM; % Full-width at half-maximum (e.g., [8 8 8])
        matlabbatch{1}.spm.spatial.smooth.dtype = 0; % Default data type
        matlabbatch{1}.spm.spatial.smooth.im = 0; % Do not mask implicit zero
        matlabbatch{1}.spm.spatial.smooth.prefix = 's'; % Prefix for smoothed file
    
        % Run SPM job manager
        spm_jobman('run', matlabbatch);
    
        smooth_pattern = '^sres_accuracy_minus_chance_set\d+\.nii$';
        smooth_accuracyFiles = spm_select('FPList', subjectDir, smooth_pattern);
        subjectID = regexp(subjectDir, 'sub-\d+', 'match', 'once');

        subject_mask = spm_select('FPList',fullfile(glm_dir,subjectID,'stats'),'mask.nii');

        % One-sample t-test configuration
        matlabbatch = [];
        
        % Specify factorial design for one-sample t-test
        matlabbatch{1}.spm.stats.factorial_design.dir = {subjectDir};
        matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = cellstr(smooth_accuracyFiles); % Ensure column format
        matlabbatch{1}.spm.stats.factorial_design.cov = []; % No covariates
        matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1; % No threshold masking
        matlabbatch{1}.spm.stats.factorial_design.masking.im = 1; % Implicit mask
        %matlabbatch{1}.spm.stats.factorial_design.masking.em = {'E:\patient_studies\analysis\patient_MVPA\prep\aamod_segment8_00001\sub-48\structurals\c1sub-48_ses-01_run-1_T1w_0001.nii'}; % Explicit mask (if provided)
        matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1; % Omit global calculation
        matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1; % No global scaling
        matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1; % Global normalization
        
        % Run the factorial design specification
        spm_jobman('run', matlabbatch);
        
        % Estimate the model
        matlabbatch = [];
        matlabbatch{1}.spm.stats.fmri_est.spmmat = {fullfile(subjectDir, 'SPM.mat')};
        matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1; % Use classical estimation
        spm_jobman('run', matlabbatch);
        
        % Specify and estimate the contrast
        matlabbatch = [];
        matlabbatch{1}.spm.stats.con.spmmat = {fullfile(subjectDir, 'SPM.mat')};
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'Single Subject Searchlight Contrast'; % Contrast name
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = 1; % One-sample t-test (mean > 0)
        matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none'; % No session replication
        matlabbatch{1}.spm.stats.con.delete = 0; % Do not delete existing contrasts
        spm_jobman('run', matlabbatch);
        
        % Display success message
        disp('Second-level one-sample t-test analysis completed successfully.');

    end

end
