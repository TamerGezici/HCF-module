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

end
