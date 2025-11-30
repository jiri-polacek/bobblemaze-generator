% evaluating puzzle complexity using Folvarčný theorem
%
function [index]=index_Folvarcny(labyrinth, walls)
	SHIFT = 100;

	% using walls?
	wallsmode = false; walls_r = 0; walls_b = 0;
	if nargin >= 2 && ~isscalar(walls)
		wallsmode = true;
		walls_r = mod(walls, 2);
		walls_b = walls > 1;
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
	quantity_of_multi = sum(multi);

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

	% Folvarčný theorem:
	index=(solved_corners/corners)*((quantity_of_unique-(quantity_of_multi/(quantity_of_multi-multi(2)-1.5*multi(3)))^3)/quantity_of_all_without_boundary);

endfunction
