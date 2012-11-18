%{
rf.Phys (computed) # my newest table
-> rf.TrialGroup
-> ephys.Spikes
-----

%}

classdef Phys < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.Phys')
        popRel = ephys.Spikes * rf.TrialGroup
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
