dbstop if error
aa_ver5;
aap = aarecipe('E:\fMRI\fr-pr-3-AA\HCFprep\aap_parameters_user.xml','E:\fMRI\fr-pr-3-AA\HCFprep\HCF_analysis.xml');
DATA_PATH = 'E:\fMRI\fr-pr-3-AA\fmri_raw_bids\bids_3D';
ROOT_PATH = pwd;
RESULTS_DIR = 'studyb_3D';
events_folder = '3B-sr';
session_identifier = '_ses-1';
events_path = fullfile(pwd,'events',events_folder);
process_fmaps = false;
do_glm = true;
use_pct = true;

if do_glm == false
    aap = aarecipe('E:\fMRI\fr-pr-3-AA\HCFprep\aap_parameters_user.xml','E:\fMRI\fr-pr-3-AA\HCFprep\HCF_prep_only.xml');
end

aap.directory_conventions.analysisid = RESULTS_DIR;
aap.directory_conventions.rawdatadir = DATA_PATH;
aap.directory_conventions.subject_directory_format = 1;
aap.acq_details.root = ROOT_PATH;
aap.tasksettings.aamod_biascorrect_structural.tpm = fullfile(spm('dir'), 'tpm', 'TPM.nii'); 

aap.tasksettings.aamod_slicetiming.refslice = 16;
aap.tasksettings.aamod_slicetiming.autodetectSO = 1;
aap.tasksettings.aamod_smooth.FWHM = 8;

aap.tasksettings.aamod_firstlevel_model.xBF.name = 'hrf';
aap.tasksettings.aamod_firstlevel_model.xBF.UNITS = 'secs';
aap.tasksettings.aamod_firstlevel_model.includemovementpars = 1; % Include/exclude Moco params in/from DM, typical value 1

subj_list = {'sub-01','sub-02','sub-05','sub-07','sub-08','sub-09','sub-12','sub-13','sub-14','sub-19','sub-31','sub-32','sub-34','sub-37','sub-41'}; % 
tasknames = {'discrB_run-01','discrB_run-02','discrB_run-03'};
for i = 1:size(tasknames,2)
    aap = aas_addsession(aap,tasknames{i}); 
end

%% Don't touch these without asking Tamer first
aap.acq_details.numdummies = 0;
aap.acq_details.input.correctEVfordummies = 0;
aap.options.NIFTI4D = 0;
aap.options.garbagecollection = 1;
aap.tasksettings.aamod_norm_write_epi.diagnostic.streamind = 0; % Disables check reg

aap = process_subjs(subj_list,aap,DATA_PATH,session_identifier,tasknames,process_fmaps);

%% GLM processing
evnames = {};
evnames{1} = 'r1';
evnames{2} = 'r2';
evnames{3} = 'r3';
evnames{4} = 'r4';
evnames{5} = 's1';
evnames{6} = 's2';
evnames{7} = 's3';
evnames{8} = 's4';
evnames{9} = 'start';
evnames{10} = 'session_rest';
evnames{11} = 'rs';
evnames{12} = 'ITE';
n_conditions = length(evnames); 

contrasts = containers.Map;
contrasts('S_M_R') =       [-1 -1 -1 -1 1 1 1 1 0 0 0 0];
contrasts('S_M_R_2') =     [0 -1 -1 -1 0 1 1 1 0 0 0 0];
contrasts('S_M_R_POS_1') = [1 0 0 0 -1 0 0 0 0 0 0 0];
contrasts('ITE_M_SESSR') = [0 0 0 0 0 0 0 0 0 -1 0 1];
contrast_list = {'S_M_R','S_M_R_2','S_M_R_POS_1','ITE_M_SESSR'};

if do_glm
    aap = generate_model(aap,subj_list,events_path,evnames,contrast_list,contrasts);
end
if use_pct
    aap = setup_pct(aap,3,'matlab_pct','local');
end

aa_doprocessing(aap);