% A Minizinc solver to optimally allocate fibre cables to the appropriate place on a plan.

% Input parameters
array[int] of int: avail_cores;
array[int] of int: avail_lengths;

set of int: Available = 1..length(avail_cores);

array[int] of int: req_cores;
array[int] of int: req_lengths;

set of int: Required = 1..length(req_cores);

% Variables to solve
array[Available, Required] of var 0..1: assignments;
array[Required] of var 0..10000: excess_length;

constraint forall(r in Required)(
	% Each link must have exactly one fibre assigned
	sum(a in Available)(assignments[a, r]) == 1
);

constraint forall(a in Available)(
	% Each available fibre should be assigned at most once
	sum(r in Required)(assignments[a, r]) <= 1
	/\
	forall(r in Required)(
		if assignments[a, r] == 1 then
			% Available cores must equal or exceed required cores
			avail_cores[a] >= req_cores[r]
			/\
			% If a fibre is assigned, record its excess length so we can minimise it
			excess_length[r] = avail_lengths[a] - req_lengths[r]
		endif
	)
);

% Objective: minimise excess length
solve minimize sum(i in Required)(excess_length[i]);
