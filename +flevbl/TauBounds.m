%{
flevbl.TauBounds (lookup) # my newest table
tau_lb: double # lower bound of time constant tau in the meister model
tau_ub: double # upper bound (values over 10000 will be treated as inf)

-----

%}

classdef TauBounds < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.TauBounds')
    end
    methods
		function self = TauBounds(varargin)
			self.restrict(varargin{:})
		end
	end
end
