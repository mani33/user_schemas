%{
jobdb.HostsNodeclasses (manual) # my newest table
nodeclass_id: smallint unsigned # blah
host_id: smallint unsigned # blah
-----
%}

classdef HostsNodeclasses < dj.Relvar

	properties(Constant)
		table = dj.Table('jobdb.HostsNodeclasses')
	end

	methods
		function self = HostsNodeclasses(varargin)
			self.restrict(varargin)
		end
	end
end
