function hcf_reslice_rois(beta_path,roi_path)
    content = dir(fullfile(roi_path,'*.nii'));
    rois = char(content.name);
    VV=char(beta_path,rois);
    spm_reslice(VV,struct('mean',false,'which',1,'interp',0)); % 1 for linear

    % After reslicing, move the files.
    content = dir(fullfile(roi_path,'r*.nii'));
    idx = cellfun(@(x) x(1) == 'r', {content.name});
    content = content(idx);

    resliced_out_path = fullfile(roi_path,'resliced');
    % Create a new directory "resliced" if it does not exist
    if ~exist(resliced_out_path, 'dir');
        mkdir(resliced_out_path);
    end

    % Move all matching files to the "resliced" directory
    for i = 1:numel(content)
        movefile(content(i).name, fullfile(resliced_out_path, content(i).name));
    end
end