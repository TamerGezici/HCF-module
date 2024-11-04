function sessions = hcf_count_runs(glm_path, subjects, userOptions)
    sessions = [];
    for subject = 1:size(subjects,2)
        thisSubject = subjects{subject};

        if userOptions.BIDSdata == 1
            % find the position of "b" in the subject name
            b_pos = strfind(thisSubject, 'b');
            % append "-" to the position after "b"
            thisSubject = [thisSubject(1:b_pos), '-', thisSubject(b_pos+1:end)];
        end

        SPM_path = fullfile(glm_path, thisSubject, 'stats', 'SPM.mat');
        load(SPM_path);
        sessions(subject) = size(SPM.Sess,2);


        % I was trying to make a system to exclude runs, but it is not very
        % functional
        if isfield(userOptions,'exclude_sub_run')

            excluded_sessions = 0;
    
            for session = 1:sessions(subject)
                if ismember(strrep(thisSubject,"-",""), userOptions.exclude_sub_run(session))
                    excluded_sessions = excluded_sessions + 1;
                end
            end
    
            if excluded_sessions ~ 0
                sessions(subject) = sessions(subject) - excluded_sessions;
            end
        end

    end

    sessions = sessions;
end
