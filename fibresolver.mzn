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
array[Required] of var int: core_ratio;

function var int: assigned_cores(Required: r) =
	sum(a in Available)(
		if assignments[a, r] == 1 then
			avail_cores[a]
		else
			0
		endif
	);

constraint forall(r in Required)(
	% Each link must have one or more fibres assigned
	sum(a in Available)(assignments[a, r]) >= 1
	/\
	% Total cores of assigned fibres must be sufficient
	assigned_cores(r) >= req_cores[r]
	/\
	% Record the ratio of used cores
	core_ratio[r] = assigned_cores(r) div req_cores[r] - 1
	/\
	% Record excess length
	excess_length[r] = sum(a in Available)(
		if assignments[a, r] == 1 then
			avail_lengths[a] - req_lengths[r]
		else
			0
		endif
	)
);

constraint forall(a in Available)(
	% Each available fibre should be assigned at most once
	sum(r in Required)(assignments[a, r]) <= 1
);

% Objective: minimise excess length and unused cores
solve minimize sum(r in Required)(excess_length[r] + core_ratio[r] * 20);
