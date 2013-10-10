%{
fle.Models5 (computed) # my newest table
-> fle.BinnedSpikeSets

-----
pdata : longblob # model perf data
fdata: longblob # raw data
args: longblob # args


models5_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef Models5 < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('fle.Models5')
		popRel = fle.BinnedSpikeSets  % !!! update the populate relation
	end

	methods
		function self = Models5(varargin)
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
