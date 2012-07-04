%{
recdb.ClusTimeframes (manual) # my newest table
set_id: smallint unsigned # id
start: double # start time
end: double # end time
-----
%}

classdef ClusTimeframes < dj.Relvar

	properties(Constant)
		table = dj.Table('recdb.ClusTimeframes')
	end

	methods
		function self = ClusTimeframes(varargin)
			self.restrict(varargin)
		end
	end
end
