%{
flevbl.Models (computed) # my newest table
-> flevbl.BinnedSpikeSets
-> flevbl.TauBounds
-----
pdata : longblob # model perf data
fdata: longblob # raw data
args: longblob # args


models_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef Models < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('flevbl.Models')
		popRel = flevbl.BinnedSpikeSets * flevbl.TauBounds % !!! update the populate relation
	end

	methods
		function self = Models(varargin)
			self.restrict(varargin{:})
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
		%!!! compute missing fields for key here
        
            [key.pdata,key.fdata,key.args] = fit_models_ncv(key);
            self.insert(key)
		end
	end
end
