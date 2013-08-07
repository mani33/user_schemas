%{
flevbl.Models5r (computed) # my newest table
-> flevbl.BinnedSpikeSets

-----
pdata : longblob # model perf data
fdata: longblob # raw data
args: longblob # args


models5r_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef Models5r < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('flevbl.Models5r')
		popRel = flevbl.BinnedSpikeSets  % !!! update the populate relation
	end

	methods
		function self = Models5r(varargin)
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
