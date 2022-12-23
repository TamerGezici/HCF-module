% Generates a GLM model and adds it to the aap structure.
% aap is the aap structure. Receives a list of subjects, a folder to look for subject events, the name of events (as a cell array which the events are numbered and named)
% receives a list of contrasts to look for, this is necessary to loop over the contrasts container map which contains the vectors. The order of occurence in the
% contrast container map needs to be same as the order of the contrast list, as MATLAB does not have ordered hash maps.
function [aa_structure] = generate_model(aap,subj_list,events_folder,evnames,contrast_list,contrasts,model_name)
    n_conditions = length(evnames); % number of events
    for sub = 1:size(subj_list,2)
        subject_number = subj_list(sub);
        subject_number = subject_number{1};
        %your event file names need to be in sub-n format (eg. sub-17)
        event_dir = fullfile(events_folder, subject_number(1:6));
        events = [];
        if isfile([event_dir,'.csv']) % can also input .csv files
            events = readmatrix([event_dir,'.csv']);
        else
            events = load(event_dir); % only take the sub-n part for example: sub-01  (erase(subject_number(1:6),"-")) )remove - while checking for the file
            participant_name=fieldnames(events); % get the participant name as a string
            eval(strcat('events=events.',participant_name{end},';')); % take this participant from the struct
        end
        n_sessions = max(events(:,1));
        participant_sessions = 'sessions:';
        for session = 1:n_sessions % runs (or tasks)
            session_onsets = events(events(:,1)==session,2:4);
            session_name = aap.acq_details.sessions(session).name;
            participant_sessions = strcat(participant_sessions,session_name,'+'); % Sessions which will be processed will be stored in this variable.
            for condition = 1:(n_conditions) % loop through event types
                session_events = find(session_onsets(:,1)==condition); % get index of events matching current type
                if ~isempty(session_events) % if not empty.
                    durs = session_onsets(session_events,3);
                    onsets = session_onsets(session_events,2);
                    %task_name = participant_tasks{session};
                    condition_name = evnames{condition};
                    aap = aas_addevent(aap,'aamod_firstlevel_model_*',subject_number,...
                        aap.acq_details.sessions(session).name,... % run/session/taskname
                        condition_name,... % condition name (regressor name)
                        onsets',... % onsets
                        durs'); % durations
                end
            end
        end
        %% Specify contrasts PER participant here.
        %% If you will estimate a model with no contrasts, pass an empty array to the function.
        if ~isempty(contrasts)
            participant_sessions = participant_sessions(1:end-1); % removes the "+" at the end
            for i=1:size(contrast_list,2) % loop over your contrasts
                curr_contrast = contrast_list{i};
                aap = aas_addcontrast(aap, 'aamod_firstlevel_contrasts', subject_number, participant_sessions, contrasts(curr_contrast), curr_contrast, 'T');
            end
        end
    end
    aa_structure = aap;
end

