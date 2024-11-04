function [varargout] = fMRIDataMasking_mahalanobis(fullBrainVols, binaryMasks_nS, betaCorrespondence, userOptions);

import rsa.*
import rsa.fig.*
import rsa.fmri.*
import rsa.rdm.*
import rsa.sim.*
import rsa.spm.*
import rsa.stat.*
import rsa.util.*

returnHere = pwd; % We'll come back here later

%% Set defaults and check options struct
if ~isfield(userOptions, 'analysisName'), error('fMRIDataMasking:NoAnalysisName', 'analysisName must be set. See help'); end%if
if ~isfield(userOptions, 'rootPath'), error('fMRIDataMasking:NoRootPath', 'rootPath must be set. See help'); end%if
userOptions = setIfUnset(userOptions, 'subjectNames', fieldnames(fullBrainVols));
userOptions = setIfUnset(userOptions, 'maskNames', fieldnames(binaryMasks_nS.(userOptions.subjectNames{1})));

% Data
nMasks = numel(userOptions.maskNames);

nSubjects = numel(userOptions.subjectNames);

for mask = 1:nMasks
    thisMask = userOptions.maskNames{mask};
	% userOptions.roi_path
    mask_path = fullfile(userOptions.roi_path,[thisMask '.nii']);

	for subject = 1:nSubjects % and for each subject...

		% Figure out which subject this is
		thisSubject = userOptions.subjectNames{subject};
        
        if userOptions.BIDSdata
	        if isempty(strfind(thisSubject,'-'))
		        index = strfind(thisSubject,'b');
		        replace = [thisSubject(1:index) '-'];
		        thisSubject = strrep(thisSubject,'sub',replace);
            end
        end
    
        SPM_path = replaceWildcards(fullfile(userOptions.betaPath, 'SPM.mat'), '[[subjectName]]', thisSubject, '[[betaIdentifier]]', '');
        load(SPM_path);
        struct_mask.fname = mask_path;
        normalisedPatterns = noiseNormaliseBeta_roi(SPM,struct_mask);
        subj_total_runs = userOptions.subject_sessions(subject);
        maskVoxelPatterns = zeros(size(normalisedPatterns,2), size(userOptions.conditionLabels,1) , subj_total_runs);
        fprintf("\nNormalizing betas for %s ROI: %s\n", thisSubject, thisMask);
        all_beta_names = SPM.xX.name;
        betas_of_interest = userOptions.conditionLabels;

        for run_no=1:subj_total_runs
            for regressor=1:size(betas_of_interest,1)
                beta_name = betas_of_interest{regressor};
                beta_name = sprintf('Sn(%d) %s*bf(1)',run_no,beta_name);
                beta_index = find(~cellfun('isempty', strfind(all_beta_names, beta_name)));
                maskVoxelPatterns(:,regressor,run_no) = normalisedPatterns(beta_index,:);
            end
        end

        responsePatterns.(thisMask).(strrep(thisSubject,'-','')) = maskVoxelPatterns;

    end


if nargout == 1
	varargout{1} = responsePatterns;
elseif nargout > 0
	error('0 or 1 arguments out, please.');
end%if:nargout

cd(returnHere); % And go back to where you started

end%function
