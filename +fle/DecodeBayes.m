%{
fle.DecodeBayes (computed) # my newest table
-> fle.DecodeData
-> fle.BootstrapSeeds
-----
ddata: longblob # decoded output
%}

classdef DecodeBayes < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.DecodeBayes')
        popRel = fle.Keysets * fle.BootstrapSeeds  % !!! update the populate relation
    end
    
    methods
		function self = DecodeBayes(varargin)
			self.restrict(varargin{:})
		end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            dfm = fetch1(fle.DecodeData(key),'dfm');
            nUnits =  size(dfm.df.trial_spike_count_flash_test,1);
            rng(key.seed)
            subset_unit_ind = ceil(rand(1,nUnits)*nUnits);
            key.ddata = decode_bayes(dfm,'selNeu',subset_unit_ind);
            self.insert(key)
        end
    end
end
