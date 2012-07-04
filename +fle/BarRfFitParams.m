% fle.BarRfFitParams - my newest table
% I will explain what my table does here 

%{
fle.BarRfFitParams (lookup) # my newest table

resp_win_start = 30 : double                # win start time for stimulus response
resp_win_end = 100  : double                # win end time for stimulus response
---
%}

classdef BarRfFitParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.BarRfFitParams')
	end

	methods
		function self = BarRfFitParams(varargin)
			self.restrict(varargin)
		end
	end
end
