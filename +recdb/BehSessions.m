%{
recdb.BehSessions (manual) # my newest table
beh_id: smallint unsigned # blah
-----
rec_id: smallint unsigned # blah
file: varchar(256) # blah
folder: varchar(256) # blah
start_time: double # blah
end_time: double # blah
clock_offset=Null: double # blah
%}

classdef BehSessions < dj.Relvar

	properties(Constant)
		table = dj.Table('recdb.BehSessions')
	end

	methods
		function self = BehSessions(varargin)
			self.restrict(varargin)
		end
	end
end
