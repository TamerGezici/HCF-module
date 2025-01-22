% J Grahn
% MarsBaR batch script to convert roi format to image format
%% See http://marsbar.sourceforge.net
%
roi_dir = 'E:\patient_studies\analysis\patient_MVPA\rois\sub-48_FIR_rois';
%Directory with ROIs to convert

% MarsBaR version check
if isempty(which('marsbar'))
error('Need MarsBaR on the path');
end
v = str2num(marsbar('ver'));
if v < 0.35
error('Batch script only works for MarsBaR >= 0.35');
end
marsbar('on'); % needed to set paths etc

%For batch converting the contents of a directory of ROIs
roi_namearray = dir(fullfile(roi_dir, '*.mat'))
for roi_no = 1:length(roi_namearray)
    roi_array{roi_no} = maroi(fullfile(roi_dir, roi_namearray(roi_no).name));
    roi = roi_array{roi_no};
    name = strtok(roi_namearray(roi_no).name, '.')
    save_as_image(roi, fullfile(roi_dir, [name '.nii']))
end
