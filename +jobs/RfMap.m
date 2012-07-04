% jobs.RfMap - my newest table
% I will explain what my table does here 

%{
 jobs.RfMap(manual) # my newest table
-> rf.SpikeSets
<<JobFields>>


%}

classdef RfMap < dj.Relvar

	properties(Constant)
		table = dj.Table('jobs.RfMap')
	end

	methods
		function self = RfMap(varargin)
			self.restrict(varargin)
		end
	end
end
