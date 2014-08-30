%{
imc.Phys (computed) # my newest table
-> ephys.Spikes
-> imc.Stim
-----
%}

classdef Phys < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('imc.Phys')
        popRel = ephys.Spikes * imc.Stim
    end
    methods
        function self = Phys(varargin)
            self.restrict(varargin)
        end
    end
    methods (Access=protected)
        function makeTuples(self, key)
            self.insert(key);
        end
    end
end