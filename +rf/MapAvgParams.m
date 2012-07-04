%{
rf.MapAvgParams (lookup) # my newest table
min_lag = 30: smallint unsigned # minimum lag for temporal averaging of maps
max_lag = 100: smallint unsigned # minimum lag for temporal averaging of maps
-----

%}

classdef MapAvgParams < dj.Relvar

	properties(Constant)
		table = dj.Table('rf.MapAvgParams')
	end

	methods
		function self = MapAvgParams(varargin)
			self.restrict(varargin)
		end
	end
end
