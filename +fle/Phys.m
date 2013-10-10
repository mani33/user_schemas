% fle.Phys - my newest table
% I will explain what my table does here

%{
fle.Phys (computed) # my newest table
-> ephys.Spikes
-> fle.TrialGroup
-----
%}

classdef Phys < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.Phys')
        popRel = ephys.Spikes * fle.TrialGroup
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
