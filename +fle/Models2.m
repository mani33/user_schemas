%{
fle.Models2 (computed) # my newest table
-> fle.BinnedSpikeSets

-----
pdata : longblob # model perf data
fdata: longblob # raw data
args: longblob # args

models2_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef Models2 < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.Models2')
        popRel = fle.BinnedSpikeSets  % !!! update the populate relation
    end
    
    methods
        function self = Models2(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            [key.pdata,key.fdata,key.args] = fit_models_ncv(key);
            self.insert(key)
        end
    end
end
