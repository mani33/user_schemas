% fle.FlashRespStatParams - my newest table
% I will explain what my table does here 

%{
fle.FlashRespStatParams (lookup) # my newest table
alpha = 0.05: double # sigificance level
base_time = 150: smallint unsigned # time before stimulus onset for baseline firing rate
resp_win_start = 40: smallint unsigned # evoked firing rate window start
resp_win_end = 100: smallint unsigned # evoked firing rate window end
-----

%}

classdef FlashRespStatParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.FlashRespStatParams')
	end

	methods
		function self = FlashRespStatParams(varargin)
			self.restrict(varargin)
		end
	end
end
