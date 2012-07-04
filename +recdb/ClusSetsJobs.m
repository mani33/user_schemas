%{
recdb.ClusSetsJobs (manual) # my newest table

set_id: smallint unsigned # cluster set id
job_id: smallint unsigned # job id
tetrode: smallint unsigned # tetrode number
-----
%}

classdef ClusSetsJobs < dj.Relvar

	properties(Constant)
		table = dj.Table('recdb.ClusSetsJobs')
	end

	methods
		function self = ClusSetsJobs(varargin)
			self.restrict(varargin)
		end
	end
end
