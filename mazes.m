% variability should be 0-1
function mazes(filename, mazes_count, set, variability)
more off
if nargin <= 3 variability = 0.3; end

genpar=[];
dir='masks9';
setfile=['sets', filesep(), set, '.m']; 
[s,err] = stat(setfile);
if err==0 					% file exist?
	source(setfile);		% load masks set -> variables `dir', `masks' & `genpar'
else 
	error('Requested set of masks not found!');
	return
end

masks_order = mod(randperm(length(masks) + round(variability * mazes_count^2)), length(masks)) + 1;
%masks_order = randperm(6);
save_variables = ' dir';

for i=1:mazes_count
	j=masks_order(i);
	si = num2str(i);
	sj = masks{j};
	fullpath = [dir, filesep(), masks{j}];
	disp('');
	disp(['*** Generating bobble #', si, ' – ', sj]);
	disp('');
	[mask, maximus, walls] = get_mask(fullpath);
	maximus += floor(rand(1)*3)-1;
	maze = 0; sols = 0;
	while sols ~= 1
		[maze, s, path, pos, neg] = bobble(fullpath, maximus, genpar, 1);
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
end

eval(['save -text ', filename, save_variables]);

endfunction
