%{
jobdb.Hosts (manual) # my newest table
host_id: smallint unsigned # blah
-----
private_nodeclass_id = Null: smallint unsigned # id
created_at = CURRENT_TIMESTAMP: timestamp # time
updated_at = 0000-00-00 00-00-00: timestamp # time
host_name: varchar(256) # blah
%}

classdef Hosts < dj.Relvar

	properties(Constant)
		table = dj.Table('jobdb.Hosts')
	end

	methods
		function self = Hosts(varargin)
			self.restrict(varargin)
		end
	end
end
