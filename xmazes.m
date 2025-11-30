% simple wrapper xmazes.sh – xmaze.m
if ~exist('f', 'var') f='noname'; end	% output filename
if ~exist('c', 'var') c=1; end			% # of generated puzzles
if ~exist('s', 'var') s='all9x9'; end	% default masks set
xmaze(f, c, s);
