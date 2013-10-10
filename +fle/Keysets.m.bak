%{
flevbl.Keysets (manual) # my newest table

id : smallint unsigned # some temporary id
-----
keys: blob # bunch of keys
comment: varchar(250) # comment
%}

classdef Keysets < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.Keysets')
    end
    methods
		function self = Keysets(varargin)
			self.restrict(varargin{:})
		end
    end
end
