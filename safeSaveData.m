function safeSaveData(FileName, Data, results_table, subjects_table)
    [fPath, fName, fExt] = fileparts(FileName);
    if isempty(fExt)  % No '.mat' in FileName
      fExt     = '.mat';
      FileName = fullfile(fPath, [fName, fExt]);
    end
    if exist(FileName, 'file')
      % Get number of files:
      fDir     = dir(fullfile(fPath, [fName, '*', fExt]));
      fStr     = lower(sprintf('%s*', fDir.name));
      fNum     = sscanf(fStr, [fName, '%d', fExt, '*']);
      if isempty(fNum)
          fNum = 1;
      end
      newNum   = max(fNum) + 1;
      FileName = fullfile(fPath, [fName, sprintf('%d', newNum), fExt]);
    end
    save(FileName, 'Data');
    save(['table_' FileName], 'results_table');
    save(['subjects_' FileName], 'subjects_table');
    writetable(subjects_table,[strrep(FileName,'.mat','') '.csv']);
end