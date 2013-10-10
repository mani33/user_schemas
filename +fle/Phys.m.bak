% flevbl.Phys - my newest table
% I will explain what my table does here

%{
flevbl.Phys (computed) # my newest table
-> ephys.Spikes
-> flevbl.TrialGroup
-----
%}

classdef Phys < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.Phys')
        popRel = ephys.Spikes * flevbl.TrialGroup
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
