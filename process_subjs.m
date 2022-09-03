function [aa_structure] = process_subjs(subj_list,aap,DATA_PATH,session_identifier,tasknames,process_fmaps)
    for i=1:size(subj_list,2)
        if size(session_identifier,2) == 6
            session_identifier = session_identifier(2:6);
        end
        subj = subj_list{i}; % Get the subject namez
        anat_dir = fullfile(DATA_PATH,subj,session_identifier,'anat'); % Form their anatomical directory
        anat_path = dir(fullfile(anat_dir,'*run-1_T1w*.nii')); % Get the first T1.
        anat_hdr = dir(fullfile(anat_dir,'*run-1_T1w.json')); % Get the header file

        subject_data_anat = struct('fname',fullfile(anat_path.folder,anat_path.name),'hdr', fullfile(anat_hdr.folder,anat_hdr.name));
        subject_data_func = {}; % 

        fmap_dir = fullfile(DATA_PATH,subj,session_identifier,'fmap');
        fmap_path = dir(fullfile(fmap_dir,'*.nii')); % Get all fieldmaps
        fmap_hdr = dir(fullfile(fmap_dir,'*.json')); % Get the header file for fieldmap

        fmaps = {fmap_path(:).name};
        fmap_hdrs = {fmap_hdr(:).name};

        for j = 1:numel(fmaps)
            fmaps{j} = fullfile(fmap_dir,fmaps{j});
            fmap_hdrs{j} = fullfile(fmap_dir,fmap_hdrs{j});
        end
        if ~isempty(fmaps) && process_fmaps
            subject_data_fmap = struct('fname',{fmaps},'hdr',{fmap_hdrs{3}},'session','*'); 
        end
        for i = 1:size(tasknames,2)
            select_func = tasknames{i};
            func_dir = fullfile(DATA_PATH,subj,session_identifier,'func');
            func_path = dir(fullfile(func_dir,strcat('*',select_func,'*','.nii*')));
            func_hdr = dir(fullfile(func_dir,strcat('*',select_func,'*','.json')));
            if ~isempty(func_path) % if a matching task was found, add it.
                func_files = {func_path(:).name};
                for i=1:size(func_files,2)
                    func_files{i} = fullfile(func_path(1).folder,func_files{i});
                end
                subject_data_func{end+1} = struct('fname',{func_files},'hdr',fullfile(func_hdr.folder,func_hdr.name));
            else
                aas_log(aap,false,['WARNING: Task ' select_func ' was not found for ' subj]);
            end
        end
        if process_fmaps && ~isempty(subject_data_fmap)
            aap = aas_addsubject(aap,subj,'functional',subject_data_func,'structural',{subject_data_anat},'fieldmaps',{subject_data_fmap});
        else
            aap = aas_addsubject(aap,subj,'functional',subject_data_func,'structural',{subject_data_anat});
        end
    end
    aa_structure = aap;
end

