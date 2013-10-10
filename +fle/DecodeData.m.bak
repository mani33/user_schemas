%{
flevbl.DecodeData (computed) # my newest table
-> flevbl.Keysets

-----
dfm: longblob # flash mov data for bayesian decoding

%}

classdef DecodeData < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.DecodeData')
        popRel = flevbl.Keysets  % !!! update the populate relation
    end
    
    methods
		function self = DecodeData(varargin)
			self.restrict(varargin{:})
		end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            keys = fetch1(flevbl.Keysets(key),'keys');
            key.dfm = get_flash_mov_data(keys);
            self.insert(key)
        end
    end
end
