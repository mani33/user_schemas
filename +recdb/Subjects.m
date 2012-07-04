%{
recdb.Subjects (manual) # my newest table
subject_id: smallint unsigned # blah
-----
subject_name: varchar(50)# blah
%}

classdef Subjects < dj.Relvar

	properties(Constant)
		table = dj.Table('recdb.Subjects')
	end

	methods
		function self = Subjects(varargin)
			self.restrict(varargin)
		end
	end
end
