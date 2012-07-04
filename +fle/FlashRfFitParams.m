% fle.FlashRfFitParams - my newest table
% I will explain what my table does here 

%{
fle.FlashRfFitParams (lookup) # my newest table

resp_win_start = 30 : double                # win start time for stimulus response
resp_win_end = 100  : double                # win end time for stimulus response
---
%}

classdef FlashRfFitParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.FlashRfFitParams')
	end

	methods
		function self = FlashRfFitParams(varargin)
			self.restrict(varargin)
		end
	end
end
