%{
flevbl.BarRfVarExp (computed) # my newest table
-> flevbl.BarRfFit

-----
ve=0: double # variance explained by the bar receptive field fittings
%}

classdef BarRfVarExp < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('flevbl.BarRfVarExp')
		popRel = flevbl.BarRfFit  % !!! update the populate relation
	end
    methods
        function self = BarRfVarExp(varargin)
            self.restrict(varargin)
        end
    end
	methods(Access=protected)

		function makeTuples(self, key)
		%!!! compute missing fields for key here
        sm = getSpatialMap(flevbl.BarRf(key));
        res = fetch1(flevbl.BarRfFit(key),'resid');
        SST = sum((sm - mean(sm)).^2);
        SSE = sum(res.^2);
        if SST == 0
            key.ve = 0;
        else
            key.ve = 1-SSE/SST;
        end
			self.insert(key)
		end
	end
end
