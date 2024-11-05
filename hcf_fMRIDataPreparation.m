function [varargout] = hcf_fMRIDataPreparation(betaCorrespondence, userOptions)

%%% This function has been created from original RSA Toolbox function fMRIDataPreparation
%%% You need to use this function instead of original if you want to

%%% 1)use all subjects' data or all sessions of subjects
%%% original RSA toolbox gets the lowest session number across subjects data (indeed you need to arrange 
%%% them in that way; otherwise there will be an error) and only processes that number of sessions across 
%%% subjects (e.g. if the lowest number of sessions is 2, the RSA processes only 2 session of a subject even if she has 6 sessions!)
%%% The number of session is calculated in RSA analysis script subject specific 
%%% (i.e. userOptions.subject_sessions = hcf_count_runs(glm_path,userOptions.subjectNames,userOptions);, and resulting variable
%%% userOptions.subject_sessions overwritten on to default code. hcf_count_runs is a custom hcf script located in HCF-module

%%% 2)use all sessions (runs) and subjects who has missing regressors in one or more sessions
%%% While using original RSA toolbox functions, If you have missing regressors (no beta exists in that session for a regressor)
%%% in some sessions and if you do not
%%% exclude these sessions; there may be huge problems; RSA may mistakenly gets wrong beta images for a regressor 
%%% since it relies on betaCorrespondence
%%% Hence, if you have very less occasion of missing regressor; just remove these sessions
%%% Hovever, if you have too much of this, you may use this function to not loose all session data, and subject data
%%% This modified functions creates dummy beta images for the nonexisted betas. 

                    % %%%% CREATE A DUMMY BETA IF IT DOESN'T EXIST!
                    % dims = SPM.xVol.DIM; %% The dimensions of the 3D array (volume of functional scan) is obtained from SPM.mat subject-specific
                    % dummyMatrix = ones(dims(1), dims(2), dims(3));
                    % brainMatrix = dummyMatrix;
                    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
        nSessions = userOptions.subject_sessions(subject);    %%% THIS OVERWRITES ON nSessions SO THAT nSessions IS SUBJECT SPECIFIC
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
                    dims = SPM.xVol.DIM; %% The dimensions of the 3D array (volume of functional scan) is obtained from SPM.mat subject-specific
                    dummyMatrix = ones(dims(1), dims(2), dims(3));
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
