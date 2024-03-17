function ROI_data = hcf_extract_roi_data(ROI, Contrast)

    Y = spm_read_vols(spm_vol(ROI),1);
    indx = find(Y>0);
    [x,y,z] = ind2sub(size(Y),indx);

    XYZ = [x y z]';

    ROI_data = spm_get_data(Contrast, XYZ);
%     zero_columns = all(ROI_data == 0, 1); % Remove voxels of ROI which do not contain any values
%     ROI_data = ROI_data(:, ~zero_columns);
end