function hcf_denorm_rois(roi_directory,deformation_field_path,out_path)
    input_images = spm_select('FPList',roi_directory,'.nii');
    deformation_field_image = spm_select('FPList',deformation_field_path,'iy_.*\.nii$');

    job.subj.def = cellstr(deformation_field_image);
    job.subj.resample = cellstr(input_images);
    job.woptions.bb = [[-78 -112 -70];[78 76 85]];
    job.woptions.vox = [2 2 2];
    job.woptions.interp = 4;
    job.woptions.prefix = 'w';

    spm_run_norm(job);

    denormalised_images = cellstr(spm_select('FPList',roi_directory,'^w.*\.nii$'));

    for i = 1:length(denormalised_images)
        currimgname = char(denormalised_images(i));
        o = maroi_image(struct('vol', spm_vol(currimgname), 'binarize',1,'func', 'img'));
        o = maroi_matrix(o);
        saveroi(o, append(currimgname(1:end-4),'_roi','.mat'));
    end

    % Move the denormalised images
    pattern = '^w.*\.(mat|nii)$';
    content = dir(roi_directory);
    match = cellfun(@(x) ~isempty(regexp(x, pattern, 'once')), {content.name});
    content = content(match);

    native_out_path = fullfile(out_path,'native_rois');
    if ~exist(native_out_path, 'dir');
        mkdir(native_out_path);
    end

    for i = 1:numel(content)
        movefile(fullfile(roi_directory,content(i).name), fullfile(native_out_path, content(i).name));
    end

end