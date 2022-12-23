% A function which adds subjects to the aap structure.
% It receives a list of subjects (cell array), the aap structure, raw data path, session identifier (BIDS terminology) ie. _ses-1
% receives a list of tasknames to process (for example, the task name in the functional images in BIDS format) some-task_run-01_bold.nii
% to process fieldmaps, the corresponding parameter needs to be true.
% to process files as 4D NiFTI files, you must make the corresponding parameter true. (This slows down analysis, so use 3D NiFTI instead)
% 
function [aa_structure] = process_subjs(subj_list,aap,DATA_PATH,session_identifier,tasknames,process_fmaps,process_4D)
    for i=1:size(subj_list,2)
        if size(session_identifier,2) == 6
            session_identifier = session_identifier(2:6);
        end
        subj = subj_list{i}; % Get the subject namez
        anat_dir = fullfile(DATA_PATH,subj,session_identifier,'anat'); % Find their anatomical directory
        anat_path = dir(fullfile(anat_dir,'*run-1_T1w*.nii')); % Get the first structural image.
        anat_hdr = dir(fullfile(anat_dir,'*run-1_T1w*.json')); % Get the header file for the structural image

        subject_data_anat = struct('fname',fullfile(anat_path.folder,anat_path.name),'hdr', fullfile(anat_hdr.folder,anat_hdr.name)); % receive the file name and it's .json header.
        subject_data_func = {}; % 

        fmap_dir = fullfile(DATA_PATH,subj,session_identifier,'fmap');
        fmap_path = dir(fullfile(fmap_dir,'*.nii')); % Get all fieldmaps
        fmap_hdr = dir(fullfile(fmap_dir,'*.json')); % Get the header file for fieldmaps

        fmaps = {fmap_path(:).name}; % fieldmap file names and headers need to be kept seperately
        fmap_hdrs = {fmap_hdr(:).name};

        for j = 1:numel(fmaps)
            fmaps{j} = fullfile(fmap_dir,fmaps{j});
            fmap_hdrs{j} = fullfile(fmap_dir,fmap_hdrs{j});
        end
        if ~isempty(fmaps) && process_fmaps
            subject_data_fmap = struct('fname',{fmaps},'hdr',{fmap_hdrs{3}},'session','*'); % apply fieldmaps to all sessions
        end
        for i = 1:size(tasknames,2) % loop over all tasknames (the tasks which you will be processing)
            select_func = tasknames{i};
            func_dir = fullfile(DATA_PATH,subj,session_identifier,'func');
            func_path = dir(fullfile(func_dir,strcat('*',select_func,'*','.nii*'))); % select the functional NifTI files which correspond to this taskname
            func_hdr = dir(fullfile(func_dir,strcat('*',select_func,'*','.json'))); % find it's header
            if ~process_4D % if not processing 4D files, the data is added to the aap structure differently.
                if ~isempty(func_path) % if a matching task was found, add it.
                    func_files = {func_path(:).name};
                    for i=1:size(func_files,2) % in this loop, images generated from each TR are added to the structure as a cell array.
                        func_files{i} = fullfile(func_path(1).folder,func_files{i});
                    end
                    subject_data_func{end+1} = struct('fname',{func_files},'hdr',fullfile(func_hdr.folder,func_hdr.name)); % put them to a cell array which contains a structure
                else % otherwise, throw an error.
                    aas_log(aap,false,['WARNING: Task ' select_func ' was not found for ' subj]);
                end
            else % if processing 4D files, a single header and file is added.
                for i=1:size(func_path,1)
                    tmp_struct = struct('fname',fullfile(func_path(i).folder,func_path(i).name),'hdr',fullfile(func_hdr(i).folder,func_hdr(i).name));
                    subject_data_func{end+1} = tmp_struct;
                end
            end
        end
        % finally, let us add our subject to the aap structure.
        if process_fmaps && ~isempty(subject_data_fmap)
            aap = aas_addsubject(aap,subj,'functional',subject_data_func,'structural',{subject_data_anat},'fieldmaps',{subject_data_fmap});
        else
            aap = aas_addsubject(aap,subj,'functional',subject_data_func,'structural',{subject_data_anat});
        end
    end
    aa_structure = aap;
end