function hcf_replace_path_in_SPM(dir_to_search, str_to_replace, str_replacement)
% REPLACE_PATH_IN_SPM Replaces a string in the SPM.xY.VY.fname field of all SPM.mat files in a directory.

    % Use spm_select to find all 'SPM.mat' files recursively
    spm_files = spm_select('FPListRec', dir_to_search, '^SPM\.mat$');

    % Loop over all found SPM.mat files
    for i = 1:size(spm_files, 1)

        % Load the current SPM.mat file
        load(deblank(spm_files(i,:)), 'SPM');
        
        % Loop over all entries in SPM.xY.VY
        for j = 1:numel(SPM.xY.VY)
            % Replace the string in the 'fname' field
            SPM.xY.VY(j).fname = strrep(SPM.xY.VY(j).fname, str_to_replace, str_replacement);
        end
        
        % Save the modified SPM structure back to the file
        save(deblank(spm_files(i,:)), 'SPM');
    end

end
