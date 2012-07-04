%{
jobdb.Nodeclasses (manual) # my newest table
nodeclass_id: smallint unsigned # blah
-----
nodeclass_name="All hosts": varchar(256) # blah
visible = 1: double # blah
updated_at = 0000-00-00 00-00-00: timestamp # blah
created_at = CURRENT_TIMESTAMP: timestamp # blah
description = NULL: varchar(256) # blah
%}

classdef Nodeclasses < dj.Relvar

	properties(Constant)
		table = dj.Table('jobdb.Nodeclasses')
	end

	methods
		function self = Nodeclasses(varargin)
			self.restrict(varargin)
		end
	end
end
