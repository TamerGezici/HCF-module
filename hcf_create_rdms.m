% Creates RDMs in .csv format from the RSA script.
function hcf_create_rdms(rdms_path, out_path, vars, rois, subjs)
    import rsa.rdm.*

    out_path = fullfile(out_path,'RDMs_out');
    out_subjs = fullfile(out_path,'subjs');
    if exist(out_path)~=7
        mkdir(out_path);
        mkdir(out_subjs);
    end

    % Load RDMs matrice
    load(rdms_path);

    averaged_RDM = averageRDMs_subjectSession(RDMs,'subject','session');
    
    total_rois = size(RDMs,1);
    for roi=1:total_rois
        roi_RDM = averaged_RDM(roi).RDM;
        roi_out_path = fullfile(out_path);
        T = array2table(roi_RDM,'VariableNames',vars,'RowNames',vars);
        writetable(T,fullfile(roi_out_path, [rois{roi}, '.csv']),'WriteRowNames',true,'WriteVariableNames',true);
    end

    subj_averaged_RDM = averageRDMs_subjectSession(RDMs,'session');

    total_subjects = size(subj_averaged_RDM,2);
    for subj = 1:total_subjects
        subj_out_path = fullfile(out_path,'subjs',subjs{subj});
        if exist(subj_out_path)~=7
            mkdir(subj_out_path);
        end
        for roi = 1:total_rois
            subj_RDM = subj_averaged_RDM(roi,subj).RDM;
            T = array2table(subj_RDM,'VariableNames',vars,'RowNames',vars);
            writetable(T,fullfile(subj_out_path, [rois{roi}, '.csv']),'WriteRowNames',true,'WriteVariableNames',true);
        end
    end

end
