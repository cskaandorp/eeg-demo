function PSR_setpaths(folderFT, folderCoSMoMVPA, folderLIBSVM)
%% PSR_SETPATHS Set paths to all folder that are required for the analysis

	%% Fieldtrip
	try
		addpath(char(folderFT));
		ft_defaults;
	catch
		error('FieldTrip folder not found');
	end

	%% CoSMoMVPA
	try
	    addpath(fullfile(char(folderCoSMoMVPA), 'mvpa'));
	    cosmo_set_path;
	catch
	    error('CoSMoMVPA toolbox not found');
	end

	%% libsvm
	if ~(strlength(folderLIBSVM) == 0)
		try
			addpath(fullfile(folderLIBSVM, 'matlab'));
		catch
			error('libsvm not found');
		end
	end

end
