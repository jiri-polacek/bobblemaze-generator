function teritory=cover(labyrinth)
	[r,c] = size(labyrinth);
	teritory = zeros(r+2, c+2)-1;
	teritory(2:end-1, 2:end-1) = labyrinth;
endfunction
