%{
flevbl.MovStatParams (lookup) # params for MovStats table

base_win = 150: double # length of time from stimulus onset to use as baseline
resp_win = 150: double # length of time from response onset specified by latency param 
-----

%}

classdef MovStatParams < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.MovStatParams')
	end
end
