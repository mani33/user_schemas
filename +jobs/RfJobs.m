% rf.RfJobs - my newest table
% I will explain what my table does here 

%{
rf.RfJobs (manual) # my newest table
-> rf.BinnedSpikeSets
<<JobFields>>


%}

classdef RfJobs < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.RfJobs')
	end

	methods
		function self = RfJobs(varargin)
			self.restrict(varargin)
		end
	end
end
