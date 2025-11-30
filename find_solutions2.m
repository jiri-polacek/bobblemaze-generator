% searching for solutions inside given puzzle
% returns count of solutions and optionally solution vectors
%
function [before, after]=find_solutions2(labyrinth, walls, verbose)
	global verb teritory stack dirs maximus mx my sol pth wallsmode walls_r walls_b SHIFT M;
	start_time = time;
	sol = {};
	pth = {};
	SHIFT = 100;
	if nargin >= 3
		verb = verbose;
	else
		verb = 0;
	end

	% using walls?
	wallsmode = false; walls_r = 0; walls_b = 0;
	if nargin >= 2 && ~isscalar(walls)
		wallsmode = true;
		walls_r = mod(walls, 2);
		walls_b = walls > 1;
		if verb >=2 disp('Using walls mode'); end
	else
		verb = walls;
	end

	% how is labyrinth defined?
	margins = [labyrinth([1, end],:), labyrinth(:,[1, end])'];
	if all(all(margins == -1))
		teritory = labyrinth;
	else
		[r,c] = size(labyrinth);
		teritory = zeros(r+2, c+2)-1;
		teritory(2:end-1, 2:end-1) = labyrinth;
	end

	% initalisation
	maximus = max(max(labyrinth));
	[r,c] = size(teritory);
	stack = [];
	[sx, sy] = find(teritory==1);
	[mx, my] = find(teritory==maximus);
	dirs = [sx-1, sy-1];
	
	before=sum(sum(teritory>0));
	
	% marking unique numbers
	for a=1:maximus
		A = find(teritory==a);
		if length(A) == 1 
			teritory(A) += SHIFT;
		end
	end
	if verb >=2 disp(['Initial unique numbers: ', num2str(length(find(teritory>SHIFT)))]); end

	% solving using hypotheses
	connections = zeros(r, c);
	connections(sx, sy) = 1; connections(mx, my) = 1;
	[S, T, C] = solve(teritory, connections);
	do
		finish = false;
		hypo_seeds = find(and(T>1, T<SHIFT));
		seed = 0;
		while S && seed < length(hypo_seeds)
			seed++;
			hypo_T = T; hypo_C = C;
			hypo_n = hypo_T(hypo_seeds(seed));
			hypo_T(hypo_seeds(seed)) += SHIFT;
			hypo_T(find(hypo_T==hypo_n)) = 0;
			S = solve(hypo_T, hypo_C);
		end
		if ~S
			T(hypo_seeds(seed)) = 0;
			[S, T, C] = solve(T, C);
		else 
			finish = true;
		end
	until finish
	
	% remarking unique numbers
	for a=1:r*c
		if T(a) > 1 && T(a) < SHIFT
			if length(find(T==T(a))) == 1 
				T(a) += SHIFT;
			end
		end	
	end

	% regulary solve once more
	[S, T, C] = solve(T, C);

	teritory = T;
	solvetrim(mazetrim(T));
	T = teritory;

	M = T > SHIFT; M(sx, sy) = 0; M(mx, my) = 0;		% auxiliary matrix for determined steps
	T(find(T>SHIFT)) = mod(T(find(T>SHIFT)), SHIFT);
	teritory = T;
	if verb >=2 printf('Presolved '); teritory, end

	after=sum(sum(teritory>0));

endfunction

function [success, teritory, con]=solve(init_ter, init_con)
	global verb maximus wallsmode walls_r walls_b SHIFT;
	success = true; teritory = init_ter; con = init_con;
	[r,c] = size(teritory);
	do
		neg  = 0;
		for i=2:r-1
			for j=2:c-1
				if teritory(i,j) > 0  &&  con(i,j) < 2
					sample = [teritory(i-1,j) teritory(i+1,j) teritory(i,j-1) teritory(i,j+1)];
					samples_con = [con(i-1,j) con(i+1,j) con(i,j-1) con(i,j+1)];
					if wallsmode sample = sample .* ~[walls_b(i-1,j) walls_b(i,j) walls_r(i,j-1) walls_r(i,j)]; end
					valid_samples_l = length(find(sample>0));
					modus = mod(teritory(i,j), SHIFT);
					commit_sample = false;
					if valid_samples_l <= 1
						if modus ~= 1 && modus ~= maximus	% orphan
							if teritory(i,j) > SHIFT
								if verb disp('Hypo failed: mandatory orphan'); end
								success = false;
								return
							else
								teritory(i,j) = 0;
								neg++;
							end
						else
							commit_sample = true;
						end
					elseif teritory(i,j) > SHIFT && valid_samples_l <= 2 && modus ~= 1 && modus ~= maximus
						commit_sample = true;
					end
					if commit_sample
						for h=1:4
							if sample(h) > 0 && samples_con(h) < 2
								x=i; y=j;
								switch h
									case 1 x = i-1;
									case 2 x = i+1;
									case 3 y = j-1;
									case 4 y = j+1;
								end
								teritory(x,y) += SHIFT;
								con(x,y) += 1;
								con(i,j) += 1;
								teritory(find(teritory==sample(h))) = 0;
								neg++;
							end
						end
						if con(i,j) ~= 2
							if verb disp('Hypo failed: missing connection'); end
							success = false;
							return
						end
					end
					
				end
			end
		end
	until neg == 0
endfunction

% auxiliary function for axes definition in a variety direction
function a=ax_rotate(direction)
	ax = [0 -1 0; -1 0 1];
	switch direction
		case 0
			a = ax;
		case 1
			a = rot90(ax, 2) .* -1;
		case 2
			a = ax .* -1;
		case 3
			a = rot90(ax, 2);
	end
endfunction

function susc=suscipious_behind_walls(suscipious, ax, x, y)
	global walls_r walls_b;
	wX = ax; wX(find(wX==1)) = 0;
	for i=1:3
		if ax(1, i)
			suscipious(i) *= ~walls_b(wX(1,i)+x, wX(2,i)+y);
		else
			suscipious(i) *= ~walls_r(wX(1,i)+x, wX(2,i)+y);
		end
	end
	susc = suscipious;
endfunction

function sfind(x, y, direction)
	global verb teritory stack dirs maximus mx my sol pth wallsmode walls_r walls_b M;
	if teritory(x,y) == maximus									% final number found
		if length(stack) == maximus-1							% is bobble complete?
			sol{end+1} = [stack, maximus];						% add to solutions
			pth{end+1} = [dirs, direction];						% add to paths
			if verb printf(['-S-']); end
		else
			return;
		end
	else
		stack(end+1) = teritory(x,y);						% add new number to the end of stack
		dirs(end+1) = direction;							% add actual direction to the end of directions vector

		% simple progress bar
		if verb
			if length(stack) == maximus-5 
				printf('o')
			elseif length(stack) == 5
				printf('.')
			end
		end
		
		%%printf(num2str(stack(end))); printf(' ');

		m = 3; 
		if teritory(x,y) == 1								% special case at the begining
			m=4;
			dirs(end) = [];									% init direction is irrelevant
		end
		teritory(x,y) = 0;									% avoid visiting same position twice
		mtemp = M(x,y); M(x,y) = 0;							% avoid determined steps via same number
		
		% is next step determined?
		direct = false;
		ax=ax_rotate(direction);
		X = ax(1,:) + x; Y = ax(2,:) + y;
		suscipious = [M(X(1), Y(1)), M(X(2), Y(2)), M(X(3), Y(3))];
		if wallsmode suscipious = suscipious_behind_walls(suscipious, ax, x, y); end
		for f=find(suscipious==1)
			next_d = mod(f + direction + 2, 4);
			bx = ax_rotate(next_d);
			X2 = bx(1,:) + X(f); Y2 = bx(2,:) + Y(f);
			inspected = [teritory(X2(1), Y2(1)), teritory(X2(2), Y2(2)), teritory(X2(3), Y2(3))];
			if wallsmode inspected = suscipious_behind_walls(inspected, bx, ax(1,f)+x, ax(2,f)+y); end
			if length(find(inspected>0)) == 1
				next_x = X(f); next_y = Y(f);
				direct = true;
				if verb >=2 printf('^'); end
				%%printf(' -> '); printf(num2str(next_d)); printf('\n');
				break
			end
		end
		
		if direct 							% we haven't choice
			sfind(next_x, next_y, next_d);
		else
			for i=1:m
				next_d = mod(i + direction + 2, 4);
				stop = false;
				if wallsmode				% we can't go through walls
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
					next_x = x; next_y = y;
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
					if (teritory(next_x, next_y) >=1) && (maximus-length(stack)+1) >= (abs(mx-next_x) + abs(my-next_y)) && ~length(find(stack == teritory(next_x, next_y)))
						sfind(next_x, next_y, next_d);
					end
				end
			end
		end
		M(x,y) = mtemp;							% restore mandatory mark
		teritory(x,y) = stack(end);				% restore actual number
		stack(end) = [];						% remove last number from stack
		dirs(end) = [];							% remove last direction from vector
		%printf('.');
	end
endfunction


function maze=mazetrim(maze)
	global maximus wallsmode walls_r walls_b SHIFT;

	[r,c] = size(maze);

	do
		trim = 1;
		for i=2:r-2
			for j=2:c-2
				square = mod(maze(i:i+1, j:j+1), SHIFT);
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
endfunction


function solvetrim(trimmed)
	global teritory maximus wallsmode walls_r walls_b SHIFT;
	[r,c] = size(teritory);
	do
		neg  = 0;
		for i=2:r-1
			for j=2:c-1
				if trimmed(i,j) > 0
					sample = [trimmed(i-1,j) trimmed(i+1,j) trimmed(i,j-1) trimmed(i,j+1)];
					if wallsmode sample = sample .* ~[walls_b(i-1,j) walls_b(i,j) walls_r(i,j-1) walls_r(i,j)]; end
					valid_samples_l = length(find(sample>0));
					modus = mod(trimmed(i,j), SHIFT);
					if  valid_samples_l <= 1 && modus ~= 1 && modus ~= maximus	% orphan
						trimmed(i,j) = 0;
						teritory(i,j) = 0;
						neg++;
					elseif trimmed(i,j) > SHIFT && valid_samples_l <= 2 && modus ~= 1 && modus ~= maximus
						for h=1:4
							if sample(h) > 0 && sample(h) < SHIFT
								x=i; y=j;
								switch h
									case 1 x = i-1;
									case 2 x = i+1;
									case 3 y = j-1;
									case 4 y = j+1;
								end
								teritory(x,y) += SHIFT;
								trimmed(x,y) += SHIFT;
								teritory(find(teritory==sample(h))) = 0;
								neg++;
							end
						end
					end
				end
			end
		end
	until neg == 0
endfunction
