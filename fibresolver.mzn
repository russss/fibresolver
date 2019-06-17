% A Minizinc solver to optimally allocate fibre cables to the appropriate place on a plan.

% Input parameters
array[int] of int: avail_cores;
array[int] of int: avail_lengths;

set of int: Available = 1..length(avail_cores);

array[int] of int: req_cores;
array[int] of int: req_lengths;

set of int: Required = 1..length(req_cores);

int: CORE_RATIO_MAX = 10;

% Variables to solve
array[Required, Available] of var bool: assignments;
array[Required] of var 0..1000: excess_length;
array[Required] of var 0..CORE_RATIO_MAX: core_ratio;

function var int: assigned_cores(Required: r) =
	sum(a in Available)(
		if assignments[r, a] == 1 then
			avail_cores[a]
		else
			0
		endif
	);

% Assert that the total number of assigned cores meets the requirement
predicate adequate_cores(Required: r) =
 	assigned_cores(r) >= req_cores[r];

% Assert that all fibres assigned to a link are long enough
predicate adequate_lengths(Required: r) =
	forall(a in Available)(
		if assignments[r, a] == 1 then
			avail_lengths[a] >= req_lengths[r]
		endif
	);

constraint forall(r in Required)(
	% Each link must have one or more fibres assigned
	sum(a in Available)(assignments[r, a]) >= 1
	/\
	adequate_cores(r)
	/\
	adequate_lengths(r)
	/\
	% Record the ratio of used cores
	core_ratio[r] = min(assigned_cores(r) div req_cores[r] - 1, CORE_RATIO_MAX)
	/\
	% Record excess length
	excess_length[r] = sum(a in Available)(
		if assignments[r, a] == 1 then
			avail_lengths[a] - req_lengths[r]
		else
			0
		endif
	)
);

constraint forall(a in Available)(
	% Each available fibre should be assigned at most once
	sum(r in Required)(assignments[r, a]) <= 1
);

% Objective: minimise excess length and unused cores
solve minimize sum(r in Required)(excess_length[r] + core_ratio[r] * 100);

output [if a == 1 then "\n Fibre " ++ show(r) ++ ": " else "" endif ++
	show(assignments[r, a]) | r in Required, a in Available]
