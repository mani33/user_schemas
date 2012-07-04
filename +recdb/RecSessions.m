%{
recdb.RecSessions (manual) # my newest table
rec_id: smallint unsigned # blah
-----
acq_id: smallint unsigned # blah
folder: varchar(256) # blah
hammer_at_start: double # blah
n_samples: bigint unsigned  # blah
start_time: timestamp # blah
end_time: timestamp # blah
%}

classdef RecSessions < dj.Relvar

	properties(Constant)
		table = dj.Table('recdb.RecSessions')
	end

	methods
		function self = RecSessions(varargin)
			self.restrict(varargin)
		end
	end
end
