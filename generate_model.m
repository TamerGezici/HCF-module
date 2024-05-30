% Generates a GLM model and adds it to the aap structure.
% aap is the aap structure. Receives a list of subjects, a folder to look for subject events, the name of events (as a cell array which the events are numbered and named)
% receives a list of contrasts to look for, this is necessary to loop over the contrasts container map which contains the contrast vectors. The order of occurence in the
% contrast container map needs to be same as the order of the contrast list, as MATLAB does not have ordered hash maps.
function [aa_structure] = generate_model(aap,subj_list,events_folder,evnames,contrast_list,contrasts)
    missing_events_acknowledged = false;
    sessions_skipped_acknowledged = false;
    mat_files = dir(fullfile(events_folder, '*.mat'));
    non_BIDS_subjname = false;
    if ~isempty(mat_files)
        sample_subs = {mat_files.name};    
        sample_sub = sample_subs(end);
        if ~contains(sample_sub,'-') % if the events are not in sub-n format.
            non_BIDS_subjname = true;
        end
    end
    for sub = 1:size(subj_list,2)
        subject_number = subj_list(sub);
        subject_number = subject_number{1};
        event_dir = fullfile(events_folder, subject_number);
        file_ext = '';
        if non_BIDS_subjname
            event_dir = fullfile(events_folder, strrep(subject_number,'-',''));
        end
        if isfile([event_dir,'.csv'])
            file_ext = '.csv';
        end
        if isfile([event_dir,'.xlsx'])
            file_ext = '.xlsx';
        end
        if isfile([event_dir,'.mat'])
            file_ext = '.mat';
        end
        if isempty(file_ext) && ~missing_events_acknowledged
            message = sprintf('Event file for subject %s not found! Click "Ignore all subjects" to acknowledge and ignore all upcoming warnings for all subjects or click "stop" and check your subjects.',subject_number);
            choice = questdlg(message, 'Event Error', 'Ignore all subjects', 'Stop', 'Ignore all subjects');
            switch choice
                case 'Ignore all subjects'
                    missing_events_acknowledged = true;
                case 'Stop'
                    error('Stopped the script as per user request'); 
            end
        end
        if strcmp(file_ext,'.csv') || strcmp(file_ext,'.xlsx')
            events = readtable([event_dir,file_ext]);
            n_sessions = max(events.session);
            participant_sessions = 'sessions:';
            session_names = {aap.acq_details.sessions.name};
            for session = 1:n_sessions % runs (or tasks)
                session_table = events(events.session == session, :);
                session_name = aap.acq_details.sessions(session).name;
                participant_sessions = strcat(participant_sessions,session_name,'+'); % Sessions which will be processed will be stored in this variable.
                unique_session_regressors = sort(unique(session_table.event)); 
                for regressor = 1:(size(unique_session_regressors,1)) % loop through regressor types
                    current_regressor = unique_session_regressors{regressor};
                    regressor_table = session_table(strcmp(session_table.event, current_regressor), :); % get index of events matching current type
                    if ~isempty(regressor_table) % if not empty.
                        durs = regressor_table.duration;
                        onsets = regressor_table.onset;
                        aap = aas_addevent(aap,'aamod_firstlevel_model_*',subject_number,...
                            session_names{session},... % run/session/taskname
                            current_regressor,... % condition name (regressor name)
                            onsets',... % onsets
                            durs'); % durations
                    end
                end
            end
        end
        if strcmp(file_ext,'.mat') % otherwise, just load them as matrices.
            n_conditions = length(evnames); % number of events
            if n_conditions == 0
                error('No events found! When using .mat files, you must define a  cell array for your event names.');
            end
            events = [];
            events = load([event_dir, '.mat']); % only take the sub-n part for example: sub-01   )remove - while checking for the file
            participant_name=fieldnames(events); % get the participant name as a string
            eval(strcat('events=events.',participant_name{end},';')); % take this participant from the struct
            n_sessions = max(events(:,1));
            participant_sessions = 'sessions:';
            session_names = {aap.acq_details.sessions.name};
            for session = 1:n_sessions % runs (or tasks)
                session_onsets = events(events(:,1)==session,2:4);
                session_name = aap.acq_details.sessions(session).name;
                participant_sessions = strcat(participant_sessions,session_name,'+'); % Sessions which will be processed will be stored in this variable.
                for condition = 1:(n_conditions) % loop through event types
                    session_events = find(session_onsets(:,1)==condition); % get index of events matching current type
                    if ~isempty(session_events) % if not empty.
                        durs = session_onsets(session_events,3);
                        onsets = session_onsets(session_events,2);
                        condition_name = evnames{condition};
                        aap = aas_addevent(aap,'aamod_firstlevel_model_*',subject_number,...
                            session_names{session},... % run/session/taskname
                            condition_name,... % condition name (regressor name)
                            onsets',... % onsets
                            durs'); % durations
                    end
                end
            end
        end
        %% Specify contrasts PER participant here.
        %% If you will estimate a model with no contrasts, pass an empty array to the function.
        if ~isempty(contrasts)
            participant_sessions = 'sameforallsessions';
            for i=1:size(contrast_list,2) % loop over your contrasts
                curr_contrast = contrast_list{i};
                if istable(events)
                    unique_events = unique(events.event)';
                    contrast_events = regexp(contrasts(curr_contrast), '(?<=x)(.*?)(?=\||$)', 'match');
                    missing_events = setdiff(contrast_events, unique_events);
                    missing_events_str = strjoin(missing_events, ' ');
                    if ~isempty(missing_events) && ~missing_events_acknowledged
                        message = sprintf('Event(s) %s for subject %s not found! Click "Ignore all subjects" to acknowledge and ignore all upcoming warnings for all subjects or click "stop" and check your subjects.\nClick "continue" to check missing events subject-by-subject.',missing_events_str,subject_number);
                        choice = questdlg(message, 'Event Error', 'Ignore all subjects', 'Stop', 'Continue','Ignore all subjects');
                        switch choice
                            case 'Ignore all subjects'
                                missing_events_acknowledged = true;
                            case 'Stop'
                                error('Stopped the script as per user request'); 
                            case 'Continue'
                                sprintf('Moving on from %s',subject_number);
                        end
                    end
                end
                aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts', subject_number, participant_sessions, contrasts(curr_contrast), curr_contrast, 'T');
            end
        end
        % If we are doing analysis for different runs or tasks
        if (isfield(aap.options,'skip_sessions') && aap.options.skip_sessions)
            if ~sessions_skipped_acknowledged
                message = sprintf("You enabled aap.options.skip_sessions.\nThis means that if a task or run is unavailable\n" + ...
                    "for a participant, it will be skipped and replaced with the available session for that participant.\n" + ...
                    "If you don't know what this pertains to, you should disable this feature or consult Tamer before continuing analysis.\n\nClick continue if you know what you are doing.");
                choice = questdlg(message,'Warning: aap.options.skip_sessions is enabled','Cancel','Continue','Continue');
                switch choice
                    case 'Cancel'
                        error('Stopped the script as per user request'); 
                    case 'Continue'
                        sessions_skipped_acknowledged = true;
                end
            end
            if sessions_skipped_acknowledged 
                subj_acq_index = find(strcmp({aap.acq_details.subjects.subjname}, subject_number));
                subject_available_sessions = aap.acq_details.subjects(subj_acq_index).seriesnumbers{1};
                subject_available_session_indexes = find(cellfun(@isstruct, subject_available_sessions));
                session_names = {aap.acq_details.sessions(subject_available_session_indexes).name};
                subj_model_indices = find(strcmp({aap.tasksettings.aamod_firstlevel_model.model.subject}, subject_number));
                for index=1:length(subj_model_indices)
                    sess_index = subj_model_indices(index);
                    aas_log(aap,false,['WARNING: For  ' subject_number ' task or run ' session_names{index} ' will be used instead of ' aap.tasksettings.aamod_firstlevel_model.model(sess_index).session]);
                    aap.tasksettings.aamod_firstlevel_model.model(sess_index).session = session_names{index};
                end
            end
        end
    end
    aa_structure = aap;
end

