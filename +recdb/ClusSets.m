%{
recdb.ClusSets (manual) # my newest table

clus_id: smallint unsigned # cluster set id
-----
rec_id: smallint unsigned # blah
folder = Null: varchar(250) # folder name
nr = Null: smallint unsigned # number of some sort
%}

classdef ClusSets < dj.Relvar

	properties(Constant)
		table = dj.Table('recdb.ClusSets')
	end

	methods
		function self = ClusSets(varargin)
			self.restrict(varargin)
		end
	end
end
