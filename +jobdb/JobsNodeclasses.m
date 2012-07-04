%{
jobdb.JobsNodeclasses (manual) # my newest table
job_id: smallint unsigned # blah
nodeclass_id: smallint unsigned # blah
-----

%}

classdef JobsNodeclasses < dj.Relvar

	properties(Constant)
		table = dj.Table('jobdb.JobsNodeclasses')
	end

	methods
		function self = JobsNodeclasses(varargin)
			self.restrict(varargin)
		end
	end
end
