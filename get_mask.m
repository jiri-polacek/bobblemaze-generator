function [mask, recommended_max, walls]=get_mask(name)
	mask = zeros(11)-1;
	mask(2:10, 2:10) = 0;
	walls = 0;
	recommended_max = 40;

	[s,err] = stat(name);
	if err==0 source(name); end
endfunction
