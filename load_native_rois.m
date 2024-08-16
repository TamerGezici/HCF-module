function [roi_list] = load_rois(rois)
     if strcmp(rois,'md')
        roi_list = {'rwL_AI.nii','rwL_aMFG.nii','rwL_FEF.nii','rwL_IPS.nii','rwL_mMFG.nii', 'rwL_pMFG.nii', 'rwL_preSMA.nii'...
        'rwR_AI.nii','rwR_aMFG.nii', 'rwR_FEF.nii','rwR_IPS.nii','rwR_mMFG.nii', 'rwR_pMFG.nii', 'rwR_preSMA.nii',...
        'rwL_ESV.nii', 'rwR_ESV.nii'};
     end
     if strcmp(rois,'dmn')
        roi_list = {'rwR_TPJ.nii', 'rwR_TempP.nii', 'rwR_Rsp.nii', 'rwR_pIPL.nii', 'rwR_PHC.nii', 'rwR_PCC.nii','rwR_LTC.nii', 'rwR_HF.nii', 'rwR_aMPFC.nii',...
        'rwL_TPJ.nii', 'rwL_TempP.nii', 'rwL_Rsp.nii', 'rwL_pIPL.nii', 'rwL_PHC.nii', 'rwL_PCC.nii','rwL_LTC.nii', 'rwL_HF.nii', 'rwL_aMPFC.nii',...
        'rvMPFC.nii', 'rdMPFC.nii', 'rAuditory_Te3.nii'};
     end
     if strcmp(rois,'unrelated')
        roi_list = {'rwLeft_Auditory_STS1.nii','rwLeft_Auditory_Te10.nii','rwLeft_Auditory_Te11.nii','rwLeft_Auditory_Te12.nii','rwLeft_Broca_44.nii',...
        'rwLeft_Broca_45.nii','rwLeft_Motor_4a.nii','rwLeft_Motor_4p.nii','rwLeft_PSC_1.nii','rwLeft_PSC_3a.nii','rwLeft_PSC_3b.nii','rwRight_Auditory_STS1.nii',...
        'rwRight_Auditory_Te10.nii','rwRight_Auditory_Te11.nii','rwRight_Auditory_Te12.nii','rwRight_Broca_44.nii','rwRight_Broca_45.nii',...
        'rwRight_Motor_4a.nii','rwRight_Motor_4p.nii','rwRight_PSC_1.nii','rwRight_PSC_3a.nii','rwRight_PSC_3b.nii'};
     end
     if strcmp(rois,'all')
        content = dir('r*.nii');
        idx = cellfun(@(x) x(1) == 'r', {content.name});
        content = content(idx);
        roi_list = {content.name};
     end
end

