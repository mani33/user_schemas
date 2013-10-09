%{
flevbl.Bw (lookup) # my newest table
t_frac = 0.5: double # fraction of refresh period to be used as bin width
-----

%}

classdef Bw < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.Bw')
    end
    
    
    methods 
        function self = Bw(varargin)
            self.restrict(varargin{:})
        end
    end
    
end
