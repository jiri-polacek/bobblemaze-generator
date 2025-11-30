% bobble(<matrix definiton>, maximum, <generator parameters>, debug)
% 
% bobble([8, 10])
%  - makes matrix 8×10, maximum calculates as round(8*10*.6) = 48
% bobble([8, 10], 47)
%  - as above, maximum is excplicitly defined as a second parameter
% 
% bobble(get_mask('sandglass'))
%  - makes maze from defined mask, maximum calculates as 0.6*sum(sum(mask==0)) -> 39 in this case
% bobble(get_mask('sandglass'), 40)
%  - as above, maximum is excplicitly defined as the second parameter
% 
% <generator parameters>
%  - a vector of length 1–5 specifying
%    - minimal count of initial mandatory numbers
%    - minimal count of initial fake number
%    - maximal count of initial mandatory numbers
%    - maximal count of initial fake number
%    - maximum of regulary solutions (within originally generated bobble)
%  - [min_mandatory, min_fake, max_mandatory, max_fake, max_solutions]
%  - [min_mandatory, min_fake, max_solutions]
%  - [min_mandatory, min_fake]
%  - [max_solutions]
%
% debug – display debug information
%  - bobble(get_mask('bun'), 40, [], 1) – generate bobble of length 40 inside "bun" maze
%    with default generator parameters displaying debug information
%
function [labyrinth, solution, path, positive, negative]=bobble(matrix_def, max_number, gen_params, dbg)
	global debug teritory queue  wallsmode walls_r walls_b;
	global DIRECTIONS MAX_RECURSIVE_CALLS MAX_BOBBLE_GEN_ATTEMPTS;
	source('config.m');		% load config
	
	%%%% Enjoy entry values %%%%

	% 1) Debug?
	if nargin==4
		debug = dbg;
	else
		debug = false;
	end

	% 2) Generator parameters
	min_pos = MIN_MANDATORY;
	min_neg = MIN_FAKE;
	max_pos = MAX_MANDATORY;
	max_neg = MAX_FAKE;
	max_sol = MAX_SOLUTIONS;
	if nargin >= 3
		switch length(gen_params)
			case 5
				min_pos = gen_params(1);
				min_neg = gen_params(2);
				max_pos = gen_params(3);
				max_neg = gen_params(4);
				max_sol = gen_params(5);
			case 3
				min_pos = gen_params(1);
				min_neg = gen_params(2);
				max_sol = gen_params(3);
			case 2
				min_pos = gen_params(1);
				min_neg = gen_params(2);
			case 1
				max_sol = gen_params(1);
		end
	end

	% 3) Define maze shape
	walls = 0;
	if ischar(matrix_def) % we expect name of mask
		[teritory, count, walls] = get_mask(matrix_def);
		[r_max, c_max] = size(teritory);
		r_max -= 2; c_max -= 2;
	elseif isvector(matrix_def)
		r_max = matrix_def(1);
		c_max = matrix_def(2);
		teritory = zeros(r_max+2, c_max+2) - 1;
		teritory(2:end-1, 2:end-1) = zeros(r_max, c_max);
		count = round(r_max * c_max * BOBBLE_LENGTH_RATIO);				% bobble's length
	else
		teritory = matrix_def;
		[r_max, c_max] = size(matrix_def);
		r_max -= 2; c_max -= 2;
		count = round(BOBBLE_LENGTH_RATIO * sum(sum(matrix_def==0)));	% bobble's length
	end

	% 4) Bobble length is defined
	if nargin >= 2 && max_number >= 2
		count = max_number;
	end
	
	% Bobble initialization %
	queue = [1, randperm(count-2) + 1, count];			% bobble's order
	[init_x, init_y] = init_number_one(r_max, c_max);	% init bobble's start
	wallsmode = false; walls_r = 0; walls_b = 0;
	if ~isscalar(walls) 
		wallsmode = true;
		walls_r = mod(walls, 2);
		walls_b = walls > 1;
	end

	%%%% Construct bobblemaze %%%%

	% Generating bobblemaze
	[solutions, path]=generate_bobble(init_x, init_y, count, max_sol);
	if solutions > 0 && solutions <= max_sol
		[positive, negative]=fill_fakes(min_pos, min_neg, max_pos, max_neg, count);
		labyrinth = teritory(2:end-1, 2:end-1);
		solution = queue;
		path(1) = []; path = [init_x-1, init_y-1, path];
	else
		labyrinth = 0;  solution = 0;  path = 0; positive = 0;  negative = 0;
		if debug disp('Bobblemaze generating has been unsuccessful :-('); end
	end
endfunction

function y=random_number(x) % random number from interval 1–x
	y = ceil(rand(1)*x)+1;
endfunction

function [x, y]=init_number_one(r_max, c_max)
	global teritory;
	x = random_number(r_max)+1; 
	y = random_number(c_max)+1;
	while teritory(x, y) == -1
		x = random_number(r_max)+1;
		y = random_number(c_max)+1;
	end
endfunction

function [solutions, dirs]=generate_bobble(init_x, init_y, count, max_sol)
	global debug teritory counter wallsmode walls_r walls_b dirs;
	global MAX_BOBBLE_GEN_ATTEMPTS;
	
	if debug disp('## Generating bobble'); end
	if debug disp(['Max regulary solutions are: ', num2str(max_sol)]); end
	c_inserts = 0;
	temp_ter = teritory;
	do
		solutions = 0;
		dirs = [];
		counter = 1;
		teritory = temp_ter;
		c_inserts++;
		if debug disp(['Attempt: ', num2str(c_inserts)]); end
		if insert(init_x, init_y, random_number(4)-1, 1, count)
			if debug disp([' Bobble settled']); end
			%teritory
			solutions = count_solutions(teritory, count);
			if debug disp([' Solutions founded: ', num2str(solutions)]); end
		elseif debug
			disp(' Bobble not generated');
		end
	until (solutions > 0 && solutions <= max_sol) || c_inserts == MAX_BOBBLE_GEN_ATTEMPTS
endfunction

function [positive, negative]=fill_fakes(min_pos, min_neg, max_pos, max_neg, count)
	global debug teritory;
	global MAX_FILLINGS_ATTEMPTS;
	
	if debug disp('## Fullfilling maze'); end
	if debug disp(['Requiered positives: ', num2str(min_pos), '–', num2str(max_pos), '; negatives: ', num2str(min_neg), '–', num2str(max_neg)]); end
	c_filling = 0;
	temp_ter = teritory;
	do
		c_filling++;
		if debug disp(['Attempt: ', num2str(c_filling)]); end
		teritory = temp_ter;
		better_fill_in(count);
		[positive, negative, iterations]=evaluate(teritory, count);
		if debug disp([' Gen positives: ', num2str(positive), ', gen negatives: ', num2str(negative), ' – iterations: ', num2str(iterations)]); end
	until (positive >= min_pos && negative >= min_neg && positive <= max_pos && negative <= max_neg) || c_filling == MAX_FILLINGS_ATTEMPTS
endfunction

function output=avoid_full_3x3(x, y)
	global teritory wallsmode walls_r walls_b;

	output = 0;
	[r,c] = size(teritory);
	large_teritory = zeros(r+2, c+2);
	if wallsmode 
		large_walls_r = large_walls_b = large_teritory;
		large_walls_r(2:end-1, 2:end-1) = walls_r;
		large_walls_b(2:end-1, 2:end-1) = walls_b;
	end
	large_teritory(3:end-2, 3:end-2) = teritory(2:end-1, 2:end-1);
	nx = x+1; ny = y+1;
	for i=-2:0
		for j=-2:0
			m3x3 = large_teritory(nx+i:nx+i+2, ny+j:ny+j+2);
			if wallsmode && sum(sum(large_walls_r(nx+i:nx+i+2, ny+j:ny+j+1))) + sum(sum(large_walls_b(nx+i:nx+i+1, ny+j:ny+j+2))) > 2
				continue
			end
			if all(all(m3x3~=0)) 
				output = 1; 
				return
			end;
		end;
	end;
endfunction

function success=insert(x, y, direction, order, o_max)
	global teritory queue counter wallsmode walls_r walls_b dirs;
	global DIRECTIONS MAX_RECURSIVE_CALLS;

% force break for a long time recursion
	if counter++ > MAX_RECURSIVE_CALLS 
		success=false; 
		return;
	end; 

	backup = teritory(x, y);
	if backup ~= 0 % It's not possible to continue
		success = false;
		return; 
	else % write number and try to call recursion
		teritory(x, y) = queue(order);
		dirs(end+1) = direction;
		if avoid_full_3x3(x,y) % It's not good idea of making this
			success = false;
		else
			success = 1;
			if order < o_max	% All items of bobble settled?
				directions = DIRECTIONS;
				d = directions(randperm(length(directions)));
				i = 1;
				success = false;
				while ~success && i <= prod(size(d)) % count of items in the vector or matrix
					next_d = mod(d(i) + direction + 2, 4);
					stop = false;
					if wallsmode
						switch next_d
							case 0
								if walls_b(x-1, y) stop = true; end
							case 1
								if walls_r(x, y) stop = true; end
							case 2
								if walls_b(x, y) stop = true; end
							case 3
								if walls_r(x, y-1) stop = true; end
						end
					end
					if ~stop
						next_x = x; next_y =y;
						switch next_d
							case 0				% north
								next_x -= 1;
							case 1				% east
								next_y += 1;
							case 2				% south
								next_x += 1;
							case 3				% west
								next_y -= 1;
						end
						success = insert(next_x, next_y, next_d, order+1, o_max);
					else
						% disp(['STOP: ', num2str([x, y, next_d])]);
					end
					i++;
				end;
			end;
		end;
		if ~success 
			teritory(x, y) = backup;
			dirs(end) = [];
		end
	end
endfunction

function better_fill_in(max_number)  % TODO: walls
	global teritory;
	stack = mod(randperm(3*max_number), max_number) + 1;
	stack(find(stack==1 | stack==max_number)) = 0;
	pos = 1;
	[r,c] = size(teritory);
	for i=2:r-1
		for j=2:c-1
			if teritory(i,j)==0
				while (stack(pos)~=0) && any(any(teritory([i-1 i+1], [j-1 j+1])==stack(pos))) % adjacent numbers in diagonal not to be same
					pos++;
				end
				teritory(i,j) = stack(pos++);
			end;
		end
	end
endfunction

function [pos, neg, iter]=evaluate(teritory, maximus)
	global  wallsmode walls_r walls_b;
	V = []; X = []; Y = []; last = 0; iter = 0; neg = 0; pos = 0;
	[r,c] = size(teritory);
	do
		new = 0; iter++;
		for i=2:r-1
			for j=2:c-1
				if teritory(i,j)>0 && teritory(i,j) < 1000
					sample = [teritory(i-1,j) teritory(i+1,j) teritory(i,j-1) teritory(i,j+1)];
					if wallsmode sample = sample .* ~[walls_b(i-1,j) walls_b(i,j) walls_r(i,j-1) walls_r(i,j)]; end
					if length(find(sample>0)) <= 1 && teritory(i,j) ~= 1 && teritory(i,j) ~= maximus	% orphan
						teritory(i,j) = 0;
						neg++; new++;
					elseif length(find(sample>0)) <= 2 && length(find(teritory==teritory(i,j))) == 1 && teritory(i,j) ~= 1 && teritory(i,j) ~= maximus
						pos++;
						V = [V, sample(find(sample>0))];
						if sample(1) > 0 X(end+1) = i-1; Y(end+1) = j; end
						if sample(2) > 0 X(end+1) = i+1; Y(end+1) = j; end
						if sample(3) > 0 X(end+1) = i; Y(end+1) = j-1; end
						if sample(4) > 0 X(end+1) = i; Y(end+1) = j+1; end
						teritory(i,j) += 1000;											% marking required number
					end
				end
			end
		end
		% eliminating fake numbers
		for k=last+1:length(V)
			for i=2:r-1
				for j=2:c-1
					if teritory(i,j) == V(k) && i ~= X(k) && j ~= Y(k)		% fake
						teritory(i,j) = 0;
						neg++; new++;
					end
				end
			end
		end
		last = length(V);
	until new == 0
endfunction

function sol=count_solutions(teritory, maxi)
	global debug maze stack maximus c_sol bobble_length wallsmode walls_r walls_b counter2;
	start_time = time;
	counter2 = c_sol = 0;
	maze = teritory;
	maximus = maxi;
	[r,c] = size(maze);

	% phase I – simplify maze
	do
		trim = 1;
		for i=2:r-2
			for j=2:c-2
				square = maze(i:i+1, j:j+1);
				sq_walls = 0;
				W = ones(1,8);
				if wallsmode
					sq_walls = walls_r(i,j) + walls_b(i,j) + walls_b(i,j+1) + walls_r(i+1,j);
					W = ~[walls_b(i-1,j), walls_r(i,j-1), walls_b(i-1,j+1), walls_r(i,j+1), walls_b(i+1,j), walls_r(i+1,j-1), walls_b(i+1,j+1), walls_r(i+1,j+1)];
				end
				if all(all(square > 1 & square < maximus)) && ~sq_walls
					hoods = [maze(i-1,j)*W(1)+maze(i,j-1)*W(2), maze(i-1,j+1)*W(3)+maze(i,j+2)*W(4); maze(i+2,j)*W(5)+maze(i+1,j-1)*W(6), maze(i+2,j+1)*W(7)+maze(i+1,j+2)*W(8)] < 1;
					if any(all(hoods)) || any(all(hoods,2))
						maze(i:i+1, j:j+1) = maze(i:i+1, j:j+1) .* ~hoods;
						trim = 0;
					end
				end
			end
		end
	until trim;

	% phase II – recursive search for solutions
	stack = [];
	[sx, sy] = find(maze==1);
	bobble_length = sum(sum(maze>0));
	sfind(sx, sy, 0);										% recursive function call
	if maximus == 0
		sol = 0;
		if debug disp([' Forced break – min ', num2str(c_sol), ' solutions']); end
	else
		sol = c_sol;
	end
	if debug disp([' Calculation time: ', num2str(time-start_time), ' s']); end
endfunction


function sfind(x, y, direction)
	global debug maze stack maximus c_sol bobble_length wallsmode walls_r walls_b counter2;

	if counter2++ > 15000 								% force break for a long time recursion
		maximus = 0; 
		return; 
	end 
	if maze(x,y) == maximus								% final number found
		if length(stack) == bobble_length-1				% is bobble complete?
			c_sol++;
		else
			return;
		end
	else
		stack(end+1) = maze(x,y);						% add new number to the end of stack
		m = 3;
		if maze(x,y) == 1 m=4; end
		maze(x,y) = 0;
		for i=1:m
			next_d = mod(i + direction + 2, 4);
			stop = false;
			if wallsmode
				switch next_d
					case 0
						if walls_b(x-1, y) stop = true; end
					case 1
						if walls_r(x, y) stop = true; end
					case 2
						if walls_b(x, y) stop = true; end
					case 3
						if walls_r(x, y-1) stop = true; end
				end
			end
			if ~stop
				next_x = x; next_y =y;
				switch next_d
					case 0				% north
						next_x -= 1;
					case 1				% east
						next_y += 1;
					case 2				% south
						next_x += 1;
					case 3				% west
						next_y -= 1;
				end
				if maze(next_x, next_y) >= 1
					sfind(next_x, next_y, next_d);
				end
			end
		end
		maze(x,y) = stack(end);
		stack(end) = [];								% remove last number from stack
	end
endfunction
