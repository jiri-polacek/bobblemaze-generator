% evaluating puzzle complexity using Folvarčný theorem
%
function [ind]=index_Folvarcny2(labyrinth, walls)
	global  wallsmode walls_r walls_b SHIFT;
	SHIFT = 100;

	% using walls?
	wallsmode = false; walls_r = 0; walls_b = 0;
	if nargin >= 2 && ~isscalar(walls)
		wallsmode = true;
		walls_r = mod(walls, 2);
		walls_b = walls > 1;
	else
		walls=0;
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

	[pos, neg, iter]=evaluate(teritory, maximus)

	quantity_of_all_without_boundary = length(find(teritory>0)) - 2;

	% marking unique numbers
	multi = [0 0 0];
	for a=1:maximus
		A = find(teritory==a);
		l = length(A);
		if l == 1 
			teritory(A) += SHIFT;
		else
			multi(l-1)++;
		end
	end

	quantity_of_unique = length(find(teritory>SHIFT));
	quantity_of_multi = sum(multi)
	multi

	corners = 0; solved_corners = 0;
	for i=2:r-1
		for j=2:c-1
			sample = [teritory(i-1,j) teritory(i+1,j) teritory(i,j-1) teritory(i,j+1)];
			if wallsmode sample = sample .* ~[walls_b(i-1,j) walls_b(i,j) walls_r(i,j-1) walls_r(i,j)]; end
			valid_samples_l = length(find(sample>0));
			modus = mod(teritory(i,j), SHIFT);
			if valid_samples_l == 1
				corners++;
				if modus ~= 1 && modus ~= maximus solved_corners++; end
			elseif valid_samples_l == 2
				corners++;
				if teritory(i,j)>SHIFT solved_corners++; end
			end
		end
	end

	corners, solved_corners

	[before,after]=find_solutions2(labyrinth, walls)

	missing=after-maximus

	% Folvarčný theorem:
	ind0=((solved_corners)/corners)*((quantity_of_unique-(quantity_of_multi/(quantity_of_multi-multi(2)-1.5*multi(3)))^3)/quantity_of_all_without_boundary)
	
	
	%ind=ind0*(((81-before)/3+before)/(after+missing));
	ind=pos+neg+solved_corners+corners-missing;

endfunction

function [pos, neg, iter]=evaluate(teritory, maximus)
	global  wallsmode walls_r walls_b SHIFT;
	V = []; X = []; Y = []; last = 0; iter = 0; neg = 0; pos = 0;
	[r,c] = size(teritory);
	do
		new = 0; iter++;
		for i=2:r-1
			for j=2:c-1
				if teritory(i,j)>0 && teritory(i,j) < SHIFT
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
						teritory(i,j) += SHIFT;											% marking required number
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