function hcf_denorm_rois(roi_path,deformation_field_path,out_path)

    marsbar on;

    % Check if the directory contains .mat and .nii files at the same time, and throw an error if there are
    if ~isempty(dir(fullfile(roi_path, '*.mat'))) && ~isempty(dir(fullfile(roi_path, '*.nii')))
        error('The input directory contains both .mat and .nii files. Please remove either one of them. ');
    end

    % If the ROIs are .nii, convert them back to .mat

    if ~isempty(dir(fullfile(roi_path, '*.nii')))
        % Get the list of nii files in the input directory
        rois = cellstr(spm_select('FPList', roi_path, '^.+\.nii$'));

        % Iterate through the list of nii files
        for i = 1:length(rois)
            currImgName = char(rois(i));

            % Create an ROI object from the current nii file
            o = maroi_image(struct('vol', spm_vol(currImgName), 'binarize', 1, 'func', 'img'));
            o = maroi_matrix(o);

            % Save the ROI object with the modified name in the output directory
            [~, fileName, ~] = fileparts(currImgName);
            outputFileName = fullfile(out_path, [fileName, '.mat']);
            saveroi(o, outputFileName);
        end
    end

    % move the nifti files to a directory called "old_niftis"
    if ~isempty(dir(fullfile(roi_path, '*.nii')))
        mkdir(fullfile(roi_path, 'original_niftis'));
        movefile(fullfile(roi_path, '*.nii'), fullfile(roi_path, 'original_niftis'));
    end

    %For batch converting the contents of a directory of ROIs
    roi_namearray = dir(fullfile(roi_path, '*.mat'));
    for roi_no = 1:length(roi_namearray)
        roi_array{roi_no} = maroi(fullfile(roi_path, roi_namearray(roi_no).name));
        roi = roi_array{roi_no};
        name = strtok(roi_namearray(roi_no).name, '.');
        save_as_image(roi, fullfile(roi_path, [name '.nii']));
    end

    % move the .mat files to a directory called "old_mats"
    mkdir(fullfile(roi_path, 'old_mats'));
    movefile(fullfile(roi_path, '*.mat'), fullfile(roi_path, 'old_mats'));

    % Rename the moved files by adding "_roi" before the file extension
    moved_files = dir(fullfile(roi_path, 'old_mats', '*.mat'));
    for i = 1:length(moved_files)
        [~, name, ext] = fileparts(moved_files(i).name);
        new_name = [name, '_roi', ext];
        movefile(fullfile(roi_path, 'old_mats', moved_files(i).name), fullfile(roi_path, 'old_mats', new_name));
    end

    % Denormalize the ROIs
    input_images = spm_select('FPList', roi_path, '.nii');
    deformation_field_image = spm_select('FPList', deformation_field_path, 'iy_.*\.nii$');

    input_images = cellstr(input_images);
    input_images = deblank(input_images);

    for roi=1:size(input_images,1)

        input_image = input_images{roi};
        job.subj.def = cellstr(deformation_field_image);
        job.subj.resample = cellstr(input_image);
        job.woptions.bb = [[-78 -112 -70];[78 76 85]];
        job.woptions.vox = [2 2 2];
        job.woptions.interp = 4;
        job.woptions.prefix = 'w';
    
        spm_run_norm(job);

    end

    denormalised_images = cellstr(spm_select('FPList', roi_path, '^w.*\.nii$'));

    for i = 1:length(denormalised_images)
        currimgname = char(denormalised_images(i));
        o = maroi_image(struct('vol', spm_vol(currimgname), 'binarize',1,'func', 'img'));
        o = maroi_matrix(o);
        saveroi(o, append(currimgname(1:end-4),'_roi','.mat'));
    end

    % Move the denormalised images
    pattern = '^w.*\.(mat|nii)$';
    content = dir(roi_path);
    match = cellfun(@(x) ~isempty(regexp(x, pattern, 'once')), {content.name});
    content = content(match);

    native_out_path = fullfile(out_path,'native_rois');
    if ~exist(native_out_path, 'dir');
        mkdir(native_out_path);
    end

    for i = 1:numel(content)
        movefile(fullfile(roi_path,content(i).name), fullfile(native_out_path, content(i).name));
    end
    
end