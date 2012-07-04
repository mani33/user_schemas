%{
jobdb.Dependencies (manual) # my newest table
job_id: smallint unsigned # blah
depends_on_id: smallint unsigned # blah
-----
%}

classdef Dependencies < dj.Relvar

	properties(Constant)
		table = dj.Table('jobdb.Dependencies')
	end

	methods
		function self = Dependencies(varargin)
			self.restrict(varargin)
		end
	end
end
