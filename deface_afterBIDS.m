% Adem YAZICI
% This script processes anatomical T1w NIfTI files in a BIDS-like directory structure.
% It performs the following tasks:
% 1. Searches for all T1w NIfTI files in "anat" directories across all subjects and sessions.
% 2. Uses the spm_deface function to deface the T1w images to anonymize them.
% 3. Removes the "anon_" prefix from the resulting defaced files.
% 4. Deletes the original (non-defaced) T1w files.

% Define the base directory
base_dir = 'D:\STUDY2_OZGE\data_bids_4D_defaced'; % Change this to the BIDS root directory 

% Get a list of all subject directories
subject_dirs = dir(fullfile(base_dir, 'sub-*'));

% Loop through each subject
for i = 1:length(subject_dirs)
    subj_dir = fullfile(subject_dirs(i).folder, subject_dirs(i).name);
    
    % Find all session folders within the subject folder
    session_dirs = dir(fullfile(subj_dir, 'ses-*'));
    for j = 1:length(session_dirs)
        session_dir = fullfile(session_dirs(j).folder, session_dirs(j).name);
        
        % Define the 'anat' directory path
        anat_dir = fullfile(session_dir, 'anat');
        if isfolder(anat_dir)
            % Find all T1w NIfTI files
            t1_files = dir(fullfile(anat_dir, '*_T1w.nii'));
            
            % Process each T1w file
            for k = 1:length(t1_files)
                t1_file_path = fullfile(t1_files(k).folder, t1_files(k).name);
                
                % Display progress
                fprintf('Processing: %s\n', t1_file_path);
                
                try
                    % Perform defacing
                    spm_deface(t1_file_path);

                    % Delete the original file
                    delete(t1_file_path);
                    fprintf('Deleted original file: %s\n', t1_file_path);
                    
                    % Construct the defaced file path
                    [filepath, filename, ext] = fileparts(t1_file_path);
                    defaced_file_path = fullfile(filepath, ['anon_' filename ext]);
                    
                    % Check if the defaced file exists with anon_ prefix
                    if isfile(defaced_file_path)
                        % Remove the 'anon_' prefix
                        new_defaced_file_path = fullfile(filepath, [filename ext]);
                        movefile(defaced_file_path, new_defaced_file_path);
                        fprintf('Renamed defaced file: %s\n', new_defaced_file_path);
                    else
                        warning('Defaced file not found: %s\n', defaced_file_path);
                    end
                    

                catch ME
                    fprintf('Error processing %s: %s\n', t1_file_path, ME.message);
                end
            end
        else
            fprintf('No anat directory in %s\n', session_dir);
        end
    end
end

fprintf('Defacing complete.\n');
