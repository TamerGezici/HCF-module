function [varargout] = hcf_fMRIDataPreparation(betaCorrespondence, userOptions)

import rsa.*
import rsa.fig.*
import rsa.fmri.*
import rsa.rdm.*
import rsa.sim.*
import rsa.spm.*
import rsa.stat.*
import rsa.util.*

returnHere = pwd; % We'll return to the pwd when the function has finished

%% Set defaults and check options struct
if ~isfield(userOptions, 'analysisName'), error('fMRIDataPreparation:NoAnalysisName', 'analysisName must be set. See help'); end%if
if ~isfield(userOptions, 'rootPath'), error('fMRIDataPreparation:NoRootPath', 'rootPath must be set. See help'); end%if
if ~isfield(userOptions, 'betaPath'), error('fMRIDataPreparation:NoBetaPath', 'betaPath must be set. See help'); end%if
if ~isfield(userOptions, 'subjectNames'), error('fMRIDataPreparation:NoSubjectNames', 'subjectNames must be set. See help'); end%if
if (~isfield(userOptions, 'conditionLabels') && ischar(betaCorrespondence) && strcmpi(betaCorrespondence, 'SPM')), error('fMRIDataPreparation:NoConditionLabels', 'conditionLables must be set if the data is being extracted from SPM.'); end%if

% The filenames contain the analysisName as specified in the user options file
ImageDataFilename = [userOptions.analysisName, '_ImageData.mat'];
DetailsFilename = [userOptions.analysisName, '_fMRIDataPreparation_Details.mat'];

promptOptions.functionCaller = 'fMRIDataPreparation';
promptOptions.defaultResponse = 'S';
promptOptions.checkFiles(1).address = fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename);
promptOptions.checkFiles(2).address = fullfile(userOptions.rootPath, 'Details', DetailsFilename);

overwriteFlag = overwritePrompt(userOptions, promptOptions);

if overwriteFlag

	%% Get Data

    if ischar(betaCorrespondence) && strcmpi(betaCorrespondence, 'SPM')
        betas = getDataFromSPM(userOptions);
    else
        betas = betaCorrespondence;
    end%if:SPM

	nSubjects = numel(userOptions.subjectNames);
	nConditions = size(betas, 2);
    nSessions = size(betas, 1);

	fprintf('Gathering scans.\n');

	for subject = 1:nSubjects % For each subject

		% Figure out the subject's name
		thisSubject = userOptions.subjectNames{subject};
		if userOptions.BIDSdata
			if isempty(strfind(thisSubject,'-'))
				index = strfind(thisSubject,'b');
				replace = [thisSubject(1:index) '-'];
				thisSubject = strrep(thisSubject,'sub',replace);
			end
		end

        load(fullfile(userOptions.glm_path,thisSubject,'stats','SPM.mat'));

		fprintf(['Reading beta volumes for subject number ' num2str(subject) ' of ' num2str(nSubjects) ': ' thisSubject]);
        nSessions = userOptions.subject_sessions(subject);        
		for session = 1:nSessions % For each session...
			 for condition = 1:nConditions % and each condition...
               
                condition_name = sprintf('Sn(%d) %s*bf(1)', session, userOptions.conditionLabels{condition});
                if ismember(condition_name,SPM.xX.name)
				    readPath = replaceWildcards(userOptions.betaPath, '[[betaIdentifier]]', betas(session,condition).identifier, '[[subjectName]]', thisSubject);
                    if strcmp(betaCorrespondence,'SPM')
                        brainMatrix = spm_read_vols(spm_vol(readPath));
                    else
                        load(readPath);
                        brainMatrix = betaImage;
                    end
                elseif ~ismember(condition_name,SPM.xX.name)
                    %%%% CREATE A DUMMY BETA IF IT DOESN'T EXIST!
                    dummyMatrix = ones(79, 95, 79); % May require modification incase it throws an error. These numbers are specific to your data.
                    brainMatrix = dummyMatrix;
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                end

				brainVector = reshape(brainMatrix, 1, []);
				subjectMatrix(:, condition, session) = brainVector; % (voxel, condition, session)

				clear brainMatrix brainVector;

				fprintf('.');

			end%for

		end%for

		% For each subject, record the vectorised brain scan in a subject-name-indexed structure
        %thisSubject = 'sub03';
        thisSubject = strrep(thisSubject,'-','');
		fullBrainVols.(thisSubject) = subjectMatrix; clear subjectMatrix;

		fprintf('\b:\n');

	end%for

	%% Save relevant info

	timeStamp = datestr(now);

% 	fprintf(['Saving image data to ' fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename) '\n']);
    disp(['Saving image data to ' fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename)]);
	gotoDir(userOptions.rootPath, 'ImageData');
	save(ImageDataFilename, 'fullBrainVols', '-v7.3');

% 	fprintf(['Saving Details to ' fullfile(userOptions.rootPath, 'Details', DetailsFilename) '\n']);
    disp(['Saving Details to ' fullfile(userOptions.rootPath, 'Details', DetailsFilename)]);
	gotoDir(userOptions.rootPath, 'Details');
	save(DetailsFilename, 'timeStamp', 'userOptions');
	
else
	disp(['Loading previously saved volumes from ' fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename) '...']);
	load(fullfile(userOptions.rootPath, 'ImageData', ImageDataFilename));
end%if

if nargout == 1
	varargout{1} = fullBrainVols;
elseif nargout > 0
	error('0 or 1 arguments out, please.');
end%if:nargout

cd(returnHere); % Go back (probably will never have left)

end%function
