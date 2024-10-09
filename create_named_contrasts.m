%% Creates a copy of first and second level contrast statistical maps and renames them to include the contrast name 
%% and the subject ID.
function [aa_structure] = create_named_contrasts(aap)
    output_dir = fullfile(aap.acq_details.root,aap.directory_conventions.analysisid);
    if isfield(aap.tasksettings,'aamod_firstlevel_contrasts')
        subs = {aap.tasksettings.aamod_firstlevel_contrasts.contrasts.subject};
        contrast_dir = fullfile(output_dir,"aamod_firstlevel_contrasts_00001/");
        for subj = 2:length(subs) % Starts from 2 because the first subject is empty.
            subj_dir = fullfile(contrast_dir,subs{subj},'stats');
            spm_contrasts = cellstr(spm_select('FPList',subj_dir,'^spmT.*\.nii$'));
            for con = 1:length(spm_contrasts)
                contrast_name = aap.tasksettings.aamod_firstlevel_contrasts.contrasts(subj).con(con).name;
                new_contrast_name = sprintf('%s_%s.nii', subs{subj}, contrast_name);
                copyfile(spm_contrasts{con}, fullfile(subj_dir, new_contrast_name));
            end
        end
    end
    if isfield(aap.tasksettings,'aamod_secondlevel_contrasts')
        contrasts = {aap.tasksettings.aamod_firstlevel_contrasts.contrasts(2).con.name};
        contrasts_dir = fullfile(output_dir,"aamod_secondlevel_contrasts_00001/group_stats/");
        for con = 1:length(contrasts)
            contrast_name = contrasts{con};
            contrast_dir = fullfile(contrasts_dir,contrast_name);
            spm_contrasts = cellstr(spm_select('FPList', contrast_dir, '^spm[TF].*\.nii$'));
            for i = 1:length(spm_contrasts)
                [~, name, ext] = fileparts(spm_contrasts{i});
                new_contrast_name = sprintf('%s_%s_%s%s', 'group',name, contrast_name, ext);
                copyfile(spm_contrasts{i}, fullfile(contrast_dir, new_contrast_name));
            end
        end
    end
end