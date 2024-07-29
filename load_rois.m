function [roi_list] = load_rois(rois)
     if strcmp(rois,'md')
        roi_list = {'rL_AI.nii','rL_aMFG.nii','rL_FEF.nii','rL_IPS.nii','rL_mMFG.nii', 'rL_pMFG.nii', 'rL_preSMA.nii'...
        'rR_AI.nii','rR_aMFG.nii', 'rR_FEF.nii','rR_IPS.nii','rR_mMFG.nii', 'rR_pMFG.nii', 'rR_preSMA.nii',...
        'rL_ESV.nii', 'rR_ESV.nii'};
     end
     if strcmp(rois,'dmn')
        roi_list = {'rR_TPJ.nii', 'rR_TempP.nii', 'rR_Rsp.nii', 'rR_pIPL.nii', 'rR_PHC.nii', 'rR_PCC.nii','rR_LTC.nii', 'rR_HF.nii', 'rR_aMPFC.nii',...
        'rL_TPJ.nii', 'rL_TempP.nii', 'rL_Rsp.nii', 'rL_pIPL.nii', 'rL_PHC.nii', 'rL_PCC.nii','rL_LTC.nii', 'rL_HF.nii', 'rL_aMPFC.nii',...
        'rvMPFC.nii', 'rdMPFC.nii', 'rAuditory_Te3.nii'};
     end
     if strcmp(rois,'unrelated')
        roi_list = {'rLeft_Auditory_STS1.nii','rLeft_Auditory_Te10.nii','rLeft_Auditory_Te11.nii','rLeft_Auditory_Te12.nii','rLeft_Broca_44.nii',...
        'rLeft_Broca_45.nii','rLeft_Motor_4a.nii','rLeft_Motor_4p.nii','rLeft_PSC_1.nii','rLeft_PSC_3a.nii','rLeft_PSC_3b.nii','rRight_Auditory_STS1.nii',...
        'rRight_Auditory_Te10.nii','rRight_Auditory_Te11.nii','rRight_Auditory_Te12.nii','rRight_Broca_44.nii','rRight_Broca_45.nii',...
        'rRight_Motor_4a.nii','rRight_Motor_4p.nii','rRight_PSC_1.nii','rRight_PSC_3a.nii','rRight_PSC_3b.nii'};
     end
     if strcmp(rois,'all')
        content = dir('r*.nii');
        idx = cellfun(@(x) x(1) == 'r', {content.name});
        content = content(idx);
        roi_list = {content.name};
     end
end

