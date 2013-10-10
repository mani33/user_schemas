%{
fle.Modelsf5r (computed) # my newest table
-> fle.BinnedSpikeSets

-----
pdata : longblob # model perf data
fdata: longblob # raw data
args: longblob # args


modelsf5r_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef Modelsf5r < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('fle.Modelsf5r')
		popRel = fle.BinnedSpikeSets  % !!! update the populate relation
	end

	methods
		function self = Modelsf5r(varargin)
			self.restrict(varargin{:})
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
		%!!! compute missing fields for key here
        
            [key.pdata,key.fdata,key.args] = fit_models_full_data(key);
            self.insert(key)
		end
	end
end
