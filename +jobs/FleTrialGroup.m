% jobs.FleTrialGroup - my newest table
% I will explain what my table does here 

%{
jobs.FleTrialGroup (manual) # my newest table
-> acq.Stimulation
<<JobFields>>


%}

classdef FleTrialGroup < dj.Relvar

	properties(Constant)
		table = dj.Table('jobs.FleTrialGroup')
	end

	methods
		function self = FleTrialGroup(varargin)
			self.restrict(varargin)
		end
	end
end
