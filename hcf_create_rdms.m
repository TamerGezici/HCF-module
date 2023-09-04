function hcf_create_rdms(rdms_path, vars, rois, subjs)
    
    out_path = fullfile(pwd,'RDMs');
    out_subjs = fullfile(out_path,'subjs');
    if exist(out_path)~=7
        mkdir(out_path);
        mkdir(out_subjs);
    end

    % Load RDMs matrice
    load(rdms_path);
    
    total_rois = size(RDMs,1);
    total_subs = size(RDMs,2);
    total_regressors = size(vars,2);

    subj_data = {};

    for roi=1:total_rois
        for subj=1:size(RDMs,2)

            subj_out_path = fullfile(out_path,'subjs',subjs{subj});
            if exist(subj_out_path)~=7
                mkdir(subj_out_path);
            end

            tmp_sess_matrix = {}; 
            %disp(RDMs(roi,subj).name);
            tmp_sess_matrix{1} = RDMs(roi,subj).RDM;
            %tmp_sess_matrix{2} = RDMs(roi,subj+total_subs).RDM;
            %tmp_sess_matrix{3} = RDMs(roi,subj+total_subs*2).RDM;
            %means = (tmp_sess_matrix{1}+tmp_sess_matrix{2}+tmp_sess_matrix{3})/3;
            means = (tmp_sess_matrix{1});
            subj_data{roi,subj} = means;

            T = array2table(means,...
            'VariableNames',vars, ...
            'RowNames',vars);
            writetable(T,fullfile(subj_out_path, [rois{roi}, '.csv']),'WriteRowNames',true,'WriteVariableNames',true);
        end    
    end

    row_count = size(subj_data,1);
    col_count = size(subj_data,2);

    averaged = {};
    for roi=1:row_count
        tmp_matrix = zeros(total_regressors,total_regressors);
        for col=1:col_count
            tmp_matrix = (tmp_matrix+subj_data{roi,col,:});
        end
        tmp_matrix = tmp_matrix/col_count;
        averaged{roi} = tmp_matrix;
    end

    averaged_named = {};

    for roi=1:size(averaged,2)
        T = array2table(averaged{roi},...
            'VariableNames',vars, ...
            'RowNames',vars);
        averaged_named{roi} = T;
        writetable(T,fullfile(out_path, [rois{roi}, '.csv']),'WriteRowNames',true);
    end

    save(fullfile(out_path, "subj_data.mat"),'subj_data');

end
