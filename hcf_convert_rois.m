function hcf_convert_rois(inputDir, outputDir)
    marsbar on;
    % Get the list of nii files in the input directory
    rois = cellstr(spm_select('FPList', inputDir, '^.+\.nii$'));

    % Iterate through the list of nii files
    for i = 1:length(rois)
        currImgName = char(rois(i));

        % Create an ROI object from the current nii file
        o = maroi_image(struct('vol', spm_vol(currImgName), 'binarize', 1, 'func', 'img'));
        o = maroi_matrix(o);

        % Save the ROI object with the modified name in the output directory
        [~, fileName, ~] = fileparts(currImgName);
        outputFileName = fullfile(outputDir, [fileName, '_roi.mat']);
        saveroi(o, outputFileName);
    end
end
