%% Perform second level searchlight analysis using SPM on data from TDT.

function hcf_searchlight_group(subjectsDir, smoothingFWHM)
    % Get a list of subject folders
    subjectFolders = dir(subjectsDir);
    subjectFolders = subjectFolders([subjectFolders.isdir]);
    subjectFolders = subjectFolders(~ismember({subjectFolders.name}, {'.', '..'}));

    % Initialize a cell array to store paths to smoothed images
    smoothedImages = cell(numel(subjectFolders), 1);

    % Loop through each subject folder
    for i = 1:numel(subjectFolders)
        subjectDir = fullfile(subjectsDir, subjectFolders(i).name);

        % Find the accuracy minus chance map file
        accuracyFile = fullfile(subjectDir, 'res_accuracy_minus_chance.nii');

        % Smooth the accuracy map
        matlabbatch = [];
        matlabbatch{1}.spm.spatial.smooth.data = {accuracyFile};
        matlabbatch{1}.spm.spatial.smooth.fwhm = smoothingFWHM;
        matlabbatch{1}.spm.spatial.smooth.dtype = 0;
        matlabbatch{1}.spm.spatial.smooth.im = 0;
        matlabbatch{1}.spm.spatial.smooth.prefix = 's'; % Prefix for smoothed file
        spm_jobman('run', matlabbatch);

        % Store path to smoothed image
        smoothedImages{i} = fullfile(subjectDir, ['s' spm_file(accuracyFile, 'basename'), '.' spm_file(accuracyFile, 'ext')]);
    end

    % Specify contrast for second-level analysis if needed
    % Example: one-sample t-test
    conNames = {'Group_Contrast'};
    conWeights = 1; % Equal weights for each subject

    % Specify design matrix
    designMatrix = ones(numel(subjectFolders), 1);

    % Perform second-level analysis
    matlabbatch = [];
    matlabbatch{1}.spm.stats.factorial_design.dir = {subjectsDir};
    matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = smoothedImages;
    matlabbatch{1}.spm.stats.factorial_design.des.t1.contrasts = struct('name', conNames, 'convec', conWeights);
    matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
    matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
    matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
    matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;
    spm_jobman('run', matlabbatch);

    % Estimate the model
    matlabbatch = [];
    matlabbatch{1}.spm.stats.fmri_est.spmmat = {[subjectsDir '/SPM.mat']};
    matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
    spm_jobman('run', matlabbatch);

    % Contrast estimation
    matlabbatch = [];
    matlabbatch{1}.spm.stats.con.spmmat = {[subjectsDir '/SPM.mat']};
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = conNames{1};
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = conWeights;
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
    matlabbatch{1}.spm.stats.con.delete = 0;
    spm_jobman('run', matlabbatch);
end
