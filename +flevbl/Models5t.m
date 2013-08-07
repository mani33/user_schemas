%{
flevbl.Models5t (computed) # my newest table
-> flevbl.BinnedSpikeSets

-----
pdata : longblob # model perf data
fdata: longblob # raw data
args: longblob # args


models5t_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef Models5t < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('flevbl.Models5t')
		popRel = flevbl.BinnedSpikeSets  % !!! update the populate relation
	end

	methods
		function self = Models5t(varargin)
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
