%{
recdb.AcqSessions (manual) # my newest table
acq_id: smallint unsigned # blah

-----
folder: varchar(256) # blah
processed_folder: varchar(256) # blah
subject_id: smallint unsigned # blah
%}

classdef AcqSessions < dj.Relvar

	properties(Constant)
		table = dj.Table('recdb.AcqSessions')
	end

	methods
		function self = AcqSessions(varargin)
			self.restrict(varargin)
		end
	end
end
