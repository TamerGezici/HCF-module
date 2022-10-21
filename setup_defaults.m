function [aa_struct] = setup_defaults(aap,RESULTS_DIR,DATA_PATH,ROOT_PATH,TPM_DIR,process_4D,garbage_collection)
    aap.directory_conventions.analysisid = RESULTS_DIR;
    aap.directory_conventions.rawdatadir = DATA_PATH;
    aap.directory_conventions.subject_directory_format = 1;
    aap.acq_details.root = ROOT_PATH;
    aap.tasksettings.aamod_biascorrect_structural.tpm = TPM_DIR;
    aap.tasksettings.aamod_segment8.tpm = TPM_DIR; 

    % Don't touch these without asking Tamer first
    aap.acq_details.numdummies = 0;
    aap.acq_details.input.correctEVfordummies = 0;
    aap.options.NIFTI4D = process_4D;
    aap.options.garbagecollection = garbage_collection;
    aap.tasksettings.aamod_norm_write_epi.diagnostic.streamind = 0; % Disables check reg
    %
    aa_struct = aap;
end

