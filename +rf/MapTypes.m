%{
rf.MapTypes (lookup) # my newest table
map_type_num: tinyint unsigned # may type identifier
-----
map_type: enum('Bright','Dark','Sum','Diff') # map types
%}

classdef MapTypes < dj.Relvar

	properties(Constant)
		table = dj.Table('rf.MapTypes')
	end

	methods
		function self = MapTypes(varargin)
			self.restrict(varargin)
		end
	end
end
