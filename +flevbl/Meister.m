%{
flevbl.Meister (computed) # my newest table
-> flevbl.BinnedSpikeSets

-----
pdata : longblob # model perf data
fdata: longblob # raw data
args: longblob # args

meister_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef Meister < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.Meister')
        popRel = flevbl.BinnedSpikeSets  % !!! update the populate relation
    end
    
    methods
        function self = Meister(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            [key.pdata,key.fdata,key.args] = fit_meister_3(key,'constrain',1,'patternsearch',0,'smooth',1,'gain_control',[1 0]);
            self.insert(key)
        end
    end
end
