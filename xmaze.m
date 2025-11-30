function xmaze(filename, i, set)
more off

genpar=[]; dir='masks9';
setfile=['sets', filesep(), set, '.m']; 
[s,err] = stat(setfile);
if err==0 					% file exist?
	source(setfile);		% load masks set -> variables `dir', `masks' & `genpar'
else 
	error('Requested set of masks not found!');
	return
end

j=ceil(rand(1)*length(masks));
si = num2str(i);
sj = masks{j};
fullpath = [dir, filesep(), masks{j}];
save_variables = ' dir';

[mask, maximus, walls] = get_mask(fullpath);
maximus += floor(rand(1)*3)-1;

disp('');
disp(['*** Generating bobble #', si, ' – ', sj]);
disp('');

maze = 0; sols = 0;
while sols ~= 1
	[maze, s, path, pos, neg] = bobble(fullpath, maximus, genpar);	% empty genpar -> default parameters from config.m
	if s ~= 0
		printf('  Validating uniqueness of solution ... ');
		[sols, s_na, p_na, compl] = find_solutions(maze, walls);
		if sols == 1 disp('OK'); else disp('FAILED'); end
	end
end

% complexity level
c_index=index_simple(maze, walls, [pos, neg], compl);

eval(['mw_', sj, si, '=walls;']);
eval(['mz_', sj, si, '=cover(maze);']);
eval(['ms_', sj, si, '=path;']);
eval(['mx_', sj, si, '=maximus;']);
eval(['mc_', sj, si, '=c_index;']);
save_variables = [save_variables, ' mw_', sj, si, ' mz_', sj, si, ' ms_', sj, si, ' mc_', sj, si, ' mx_', sj, si];

eval(['save -text ', filename, '-', sprintf('%.2d',i), save_variables]);

endfunction
