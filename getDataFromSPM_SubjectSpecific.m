function betas_subject_specific = getDataFromSPM_SubjectSpecific(userOptions,thisSubject)

%%% Created By Adem
%%% This function was created from original RSA toolbox function getDataFromSPM 
%%% This functions enables to get subject specific betas


% getDataFromSPM is a function which will extract from the SPM metadata the
% correspondence between the beta image filenames and the condition and session
% number.
%
% function betas_subject_specific = getDataFromSPM(userOptions)
%
%        betas_subject_specific --- The array of info.
%               betas_subject_specific(condition, session).identifier is a string which referrs
%               to the filename (not including path) of the SPM beta image.
%
%        userOptions --- The options struct.
%                userOptions.subjectNames
%                        A cell array containing strings identifying the subject
%                        names.
%                userOptions.betaPath
%                        A string which contains the absolute path to the
%                        location of the beta images. It can contain the
%                        following wildcards which would be replaced as
%                        indicated:
%                                [[subjectName]]
%                                        To be replaced with the contents of
%                                        subject.
%                                [[betaIdentifier]]
%                                        To be replaced by filenames returned in
%                                        betas_subject_specific.
%                userOptions.conditionLabels
%                        A cell array containing the names of the conditions in
%                        this experiment. Here, these will be used to find
%                        condition response beta predictor images (so make sure
%                        they're the same as the ones used for SPM!).
%  
%  Cai Wingfield 12-2009, 6-2010, 8-2010

    import rsa.*
import rsa.fig.*
import rsa.fmri.*
import rsa.rdm.*
import rsa.sim.*
import rsa.spm.*
import rsa.stat.*
import rsa.util.*

	%% Set defaults and check for problems.
	if ~isfield(userOptions, 'betaPath'), error('getDataFromSPM:NoBetaPath', 'userOptions.betaPath is not set. See help.'); end%if
	if ~isfield(userOptions, 'subjectNames'), error('getDataFromSPM:NoSubjectNames', 'userOptions.subjectNames is not set. See help.'); end%if
	if ~isfield(userOptions, 'conditionLabels'), error('getDataFromSPM:NoConditionLabels', 'userOptions.conditionLabels is not set. See help.'); end%if
        
    % max_session_subject = find(userOptions.subject_sessions == max(userOptions.subject_sessions));
    % max_session_subject = max_session_subject(1);

    %firstSubject = userOptions.subjectNames{max_session_subject};

	% if userOptions.BIDSdata
	% 	if isempty(strfind(thisSubject,'-'))
	% 		index = strfind(thisSubject,'b');
	% 		replace = [thisSubject(1:index) '-'];
	% 		thisSubject = strrep(thisSubject,'sub',replace);
	% 	end
	% end

	readFile = replaceWildcards(fullfile(userOptions.betaPath, 'SPM.mat'), '[[subjectName]]', thisSubject, '[[betaIdentifier]]', '');
	load(readFile);
	nBetas = max(size(SPM.Vbeta));

	nConditions = numel(userOptions.conditionLabels);

	% Extract all info

	highestSessionNumber = 0;

	for betaNumber = 1:nBetas % For each beta file...

		% Get the description of the beta file
		thisBetaDescrip = SPM.Vbeta(betaNumber).descrip;

		% Extract from it the file name, the session number and the condition name
		[thisBetaName, thisSessionNumber, thisConditionName] = extractSingleBetaInfo(thisBetaDescrip);

		% Check if it's one of the conditions
		thisBetaIsACondition = false; % (What a delicious variable name!)
		for condition = 1:nConditions

			thisBetaIsACondition = strcmpi(thisConditionName, userOptions.conditionLabels{condition}); % Check if it's a condition specified by the user
			conditionNumber = condition; % Record the condition number that it is
			if thisBetaIsACondition, break; end%if

		end%for

		% Now only proceed if we're looking at a condition
		if thisBetaIsACondition
		
			% Keep a tally of the higest run yet
			highestSessionNumber = max(highestSessionNumber, thisSessionNumber);
			
			% Store the file name in the betas_subject_specific struct
            % Adem's modification
			betas_subject_specific(thisSessionNumber, conditionNumber).identifier = [thisBetaName '.nii'];
			
		end%if
	end%for
    % Written by Tamer
    if userOptions.select_runs ~= 0
        tmp_betas = struct();
        selected_runs = userOptions.select_runs;
        for run_no = selected_runs(1):selected_runs(end)
            run_subtract = abs(1-run_no);
            total_betas = size(betas_subject_specific(run_no,:),2);
            for beta_no = 1:total_betas
                tmp_betas(run_no-run_subtract,beta_no).identifier = betas_subject_specific(run_no,beta_no).identifier;
            end
        end
        betas_subject_specific = tmp_betas;
    end
end%function

%% Subfunctions: %%

% spm_spm:beta (0001) - Sn(1) all_events*bf(1)
function [betaName, sessionNumber, conditionName] = extractSingleBetaInfo(strIn)

	import rsa.*
import rsa.fig.*
import rsa.fmri.*
import rsa.rdm.*
import rsa.sim.*
import rsa.spm.*
import rsa.stat.*
import rsa.util.*

	openBrackets = findstr(strIn, '(');
	closedBrackets = findstr(strIn, ')');
	star = findstr(strIn, '*');

	inFirstBrackets = strIn(openBrackets(1)+1:closedBrackets(1)-1);
	betaName = ['beta_' inFirstBrackets];

	inSecondBrackets = strIn(openBrackets(2)+1:closedBrackets(2)-1);
	sessionNumber = str2num(inSecondBrackets);

	conditionName = strIn(closedBrackets(2)+2:star-1);
end%function
