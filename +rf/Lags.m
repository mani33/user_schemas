%{
rf.Lags (lookup) # different lags you want to compute receptive field map by reverse corr

lag: smallint unsigned # lag in msec
-----

%}

classdef Lags < dj.Relvar

	properties(Constant)
		table = dj.Table('rf.Lags')
	end

	methods
		function self = Lags(varargin)
			self.restrict(varargin)
		end
	end
end
