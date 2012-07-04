% fle.StatsParams - my newest table
% I will explain what my table does here 

%{
fle.StatsParams (lookup) # my newest table

firing_rate_th = 10: smallint unsigned # Hz - threshold firing rate to include in analysis
firing_rate_change_th = 5: tinyint unsigned # Hz threshold for change in evoked firing rate from baseline
base_time = 150: smallint unsigned # baseline firing rate window before stim onset
resp_win_start = 40: smallint unsigned # evoked firing rate window start
resp_win_end = 100: smallint unsigned # evoked firing rate window end
alpha = 0.05: double # significance level
-----

%}

classdef StatsParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.StatsParams')
	end

	methods
		function self = StatsParams(varargin)
			self.restrict(varargin)
		end
	end
end
