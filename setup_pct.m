function [aa_struct] = use_pct(aap,num_workers,where,pool_profile)
    aap.options.wheretoprocess=where; 
    aap.directory_conventions.poolprofile = pool_profile;
    aap.options.aaparallel.numberofworkers = num_workers; %
    aa_struct = aap;
end

