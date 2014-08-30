%{
imc.SpikeSets (computed) # my newest table
-> imc.Phys
-> imc.SpikeWinParams

-----
spikesets_ts = CURRENT_TIMESTAMP:   timestamp # do not edit
%}


classdef SpikeSets < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('imc.SpikeSets')
        popRel = imc.Phys * imc.SpikeWinParams;
    end
    
    methods
        function self = SpikeSets(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % Populate subtables
            makeTuples(imc.TrialSpikes,key)
        end
    end
end