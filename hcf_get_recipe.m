function [recipe] = hcf_get_recipe(path,tasklist,user_param_name)
   user_param_path = fullfile(path,[user_param_name '.xml']);
   recipe_path = '';
   recipe_folder = fullfile(path,'recipes');
   if strcmp(tasklist,'prep')
      recipe_path = fullfile(recipe_folder,['preprocessing','.xml']);
   elseif strcmp(tasklist,'prep_clinical')
      recipe_path = fullfile(recipe_folder,['preprocessing_clinical','.xml']);
   elseif strcmp(tasklist,'segment_clinical') % This is to get proper transformation parameters from MNI to native space. No need to use it.
      recipe_path = fullfile(recipe_folder,['segment_clinical','.xml']);
   elseif strcmp(tasklist,'prep_native')
      recipe_path = fullfile(recipe_folder,['preprocessing_native','.xml']);
   elseif strcmp(tasklist,'prep_DARTEL')
      recipe_path = fullfile(recipe_folder,['preprocessing_DARTEL','.xml']);
   elseif strcmp(tasklist,'prep_fmap')
      recipe_path = fullfile(recipe_folder,['preprocessing_fieldmap','.xml']);
   elseif strcmp(tasklist,'prep_gui')
      recipe_path = fullfile(recipe_folder,['preprocessing_gui','.xml']);
   elseif strcmp(tasklist,'structural_DARTEL')
      recipe_path = fullfile(recipe_folder,['structural_dartel','.xml']);
   elseif strcmp(tasklist,'glm')
      recipe_path = fullfile(recipe_folder,['GLM','.xml']);
   elseif strcmp(tasklist,'glm_design')
      recipe_path = fullfile(recipe_folder,['GLM_design','.xml']);
   elseif strcmp(tasklist,'glm_contrast')
      recipe_path = fullfile(recipe_folder,['GLM_contrast','.xml']);
   elseif strcmp(tasklist,'glm_group')
      recipe_path = fullfile(recipe_folder,['GLM_group','.xml']);
   elseif strcmp(tasklist,'glm_group_nomask')
      recipe_path = fullfile(recipe_folder,['GLM_group_nomask','.xml']);
   elseif strcmp(tasklist,'glm_threshold')
      recipe_path = fullfile(recipe_folder,['GLM_threshold','.xml']);
   end
   recipe = aarecipe(user_param_path,recipe_path);
end

