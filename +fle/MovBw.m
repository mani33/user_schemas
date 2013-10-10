%{
fle.MovBw (lookup) # bin width for BinnedMovResp table, as a fraction of refresh period

frac_t = 0.5: double # fraction of refresh period to use as bin width
-----

%}

classdef MovBw < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.MovBw')
	end
end
