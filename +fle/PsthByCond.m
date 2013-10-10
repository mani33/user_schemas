%{
fle.PsthByCond (computed) # my newest table
-> fle.BinTimesByCond
-> fle.Phys

-----
mean_fr : blob # trial averaged mean firing rate
psthbycond_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef PsthByCond < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.PsthByCond')
        popRel = (fle.BinTimesByCond * fle.Phys) & fle.BinTrialResp  % !!! update the populate relation
    end
    
    methods
        function self = PsthByCond(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            r = fetchn(fle.BinTrialResp(key),'spike_counts');
            r = [r{:}];
            bw = fetch1(fle.BinTimesByCond(key),'bw_t');
            key.mean_fr = mean(r,2)*1000/bw;
            
            %!!! compute missing fields for key here
            self.insert(key)
            
        end
    end
end
