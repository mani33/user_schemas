% jobs.RfSpikeSets - my newest table
% I will explain what my table does here 

%{
jobs.RfSpikeSets (manual) # my newest table
-> rf.TrialGroup
<<JobFields>>


%}

classdef RfSpikeSets < dj.Relvar

	properties(Constant)
		table = dj.Table('jobs.RfSpikeSets')
	end

	methods
		function self = RfSpikeSets(varargin)
			self.restrict(varargin)
		end
	end
end
