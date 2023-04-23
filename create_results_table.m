function [table, subjects_table] = create_results_table(roi_list,condition_results,subject_folders)
    [h p c] = ttest(condition_results-50);
    upper_index = size(roi_list,2)*2;
    up = [1:2:upper_index];
    low = [2:2:upper_index];
    acc = mean(condition_results);
    acc_minus_50 = mean(condition_results-50);
    results_array = [acc; acc_minus_50; h; p; c(up); c(low)];
    table = array2table(results_array,"VariableNames",string(roi_list),"RowNames",{'acc','acc_minus_fifty','h','p','cu','cl'});
    subjects_table = array2table(condition_results,"VariableNames",string(roi_list),"RowNames",subject_folders);
end

