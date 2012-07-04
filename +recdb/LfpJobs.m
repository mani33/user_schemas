%{
recdb.LfpJobs (manual) # my newest table
rec_id: smallint unsigned # blah
job_id: smallint unsigned # blah
-----

%}

classdef LfpJobs < dj.Relvar

	properties(Constant)
		table = dj.Table('recdb.LfpJobs')
	end

	methods
		function self = LfpJobs(varargin)
			self.restrict(varargin)
		end
	end
end
