%{
recdb.ClusSetsBeh (manual) # my newest table
clus_id: smallint unsigned # blah
beh_id: smallint unsigned # blah
-----

%}

classdef ClusSetsBeh < dj.Relvar

	properties(Constant)
		table = dj.Table('recdb.ClusSetsBeh')
	end

	methods
		function self = ClusSetsBeh(varargin)
			self.restrict(varargin)
		end
	end
end
