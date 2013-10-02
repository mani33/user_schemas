%{
rf.SnrParams (lookup) # parameters for computing SNR in SnrFitAvg table
mahal_dist: double # Mahalanobis distance for computing signal-to-noise ratio
-----

%}

classdef SnrParams < dj.Relvar

	properties(Constant)
		table = dj.Table('rf.SnrParams')
	end
end
