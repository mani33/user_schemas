%{
flevbl.BootstrapSeeds (lookup) # my newest table
seed: double # random number generation seeds
-----

%}

classdef BootstrapSeeds < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.BootstrapSeeds')
    end
    methods
		function self = BootstrapSeeds(varargin)
			self.restrict(varargin{:})
		end
    end
end
