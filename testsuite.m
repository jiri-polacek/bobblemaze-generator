clear
more off
load K12
vars=who;
for i=1:length(vars)
	if substr(vars{i}, 1, 2) == 'mz'
		puzzlename=substr(vars{i}, 4);
		disp('######################');
		disp(puzzlename);
		eval(['index_Folvarcny2(mz_', puzzlename, ', mw_', puzzlename, ')']);
		disp(' ');
	end
end
