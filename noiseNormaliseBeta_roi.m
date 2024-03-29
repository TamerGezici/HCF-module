function [B, roi] = noiseNormaliseBeta_roi(SPM,struct_mask)
% this is a wrapper function for the rsa.spm.noiseNormaliseBeta. Given the
% SPM structure and roi information, it first loads in the pre-processed
% time series and then computes the white betas using the toolbox
% function. the input can contain a file name in struct_msk.fname. In that
% case, it considers a roi that is composed of all non-zero voxels within
% the file. it can also contain a triplet as the center and a radius. In
% that case it defines a sphere around the center and extracts the time
% series for the spherical ROI. If both are provided the ROI would be the
% intrsection of the sphere and the binary mask. the output is the white
% betas for all the voxels in the roi. there would be one number per voxel
% per regressor in the design matrix (so that the function is general).
% Note that computing LDC RDMs would be possible by calling the
% rsa.distanceLDC on the B together with condition and run indices). Also
% taking the Euclidean distance of the white activity patterns would be
% equivalent to the Mahalanobis distance. in case you are running this on a
% different machine that you used to do your first-level stats, you will
% need Joern's spmj_move_rawdata to modify the SPM structure and give you
% access. 
% inputs: SPM structure, struct_mask:
% struct_mask.fname full path to the binary ROI file
% struct_mask.center: [x y z] coordinats of the sphere center in voxel
% space
% struct_mask.rad: sphere radius in mm
% output: 
% B: beta estimates for each voxel and regressor after multivariate noise
% normlisation
% HN, Nov. 2018
% you will need to add the rsatoolbox to the path before calling this
% function (link to the toolbox: https://github.com/spike3600/rsatoolbox)


volIn = SPM.xY.VY;
%% extract the ROI matrix
if isfield(struct_mask,'fname') & isfield(struct_mask,'center') & isfield(struct_mask,'rad')
    
    peakCoords = struct_mask.center;
    rad_mm = struct_mask.rad;
    temp = abs(diag(volIn(1).mat));voxSize_mm = temp(1:3);
    mapDim = volIn(1).dim;
    rad_mm = struct_mask.rad;
    roi = defineSphericalROI(peakCoords,rad_mm,voxSize_mm,mapDim,0);
    msk = spm_read_vols(spm_vol(struct_mask.fname));
    roi = roi.*msk;
elseif isfield(struct_mask,'fname')
    roi = spm_read_vols(spm_vol(struct_mask.fname));
elseif isfield(struct_mask,'center') & isfield(struct_mask,'rad')
    peakCoords = struct_mask.center;
    rad_mm = struct_mask.rad;
    temp = abs(diag(volIn(1).mat));voxSize_mm = temp(1:3);
    mapDim = volIn(1).dim;
    rad_mm = struct_mask.rad;
    roi = defineSphericalROI(peakCoords,rad_mm,voxSize_mm,mapDim,0);
else
    error('input structure should either contain file name or peak coordinates and sphere radius')
end



%% extract the raw time series for the binary ROI
% let'say you have a binary mask, msk
linVox = find(roi);
[I,J,K] = ind2sub(volIn(1).dim,linVox);
for i=1:length(volIn)
    Y(:,i)=spm_sample_vol(volIn(i),double(I),double(J),double(K),0);
end
 
%% compute the white betas
B = rsa.spm.noiseNormalizeBeta(Y',SPM);

function roi = defineSphericalROI(peakCoords,rad_mm,voxSize_mm,mapDim,monitor)
% creates a binary spherical ROI centred at a given location.
% INPUTS:
% peakCoords: a triplet as indices of the peak coordinates [x,y,z], 
% rad_mm: the radius of the spherical ROI in mm 
% voxSize_mm: a triplet for voxel size (in mm)
% mapDim: a triplet equal to the size of the to-be-created mask
 %
 % note: use spm_get_orig_coord to go from MNI to native space
 % HN, Jan 2018
 % example:
 % roi = defineSphericalROI([21 20 21],7,[3 3 3],[64 64 32],1)
[~,centerRelROI]=createVoxelSphere(rad_mm,voxSize_mm,monitor);
roi = zeros(mapDim);
for i=1:size(centerRelROI,1)
    idx = peakCoords + centerRelROI(i,:);
    roi(idx(1),idx(2),idx(3)) = 1;
end
