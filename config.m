% Config file for bobblemaze generator

MIN_MANDATORY = 2;
MIN_FAKE      = 3;
MAX_MANDATORY = Inf;
MAX_FAKE      = Inf;
MAX_SOLUTIONS = Inf;

BOBBLE_LENGTH_RATIO = 0.6;

MAX_BOBBLE_GEN_ATTEMPTS = 20;
MAX_FILLINGS_ATTEMPTS    = 30;

MAX_RECURSIVE_CALLS = 8000;

% Directions: 1= left, 2=straight, 3=right
% [1 2 2 3] means 50% of probability to choose straight direction as first, 25% left and 25% right
DIRECTIONS = [1 2 3 1 2 3 2];
