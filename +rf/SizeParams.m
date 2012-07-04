%{
rf.SizeParams (lookup) # my newest table
mahal_dist = 1: double # mahalanobis distance at which to compute the rf size
-----

%}

classdef SizeParams < dj.Relvar

	properties(Constant)
		table = dj.Table('rf.SizeParams')
	end

	methods
		function self = SizeParams(varargin)
			self.restrict(varargin)
		end
	end
end
