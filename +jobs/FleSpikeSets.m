%{
jobs.FleSpikeSets(manual)   # job to populate spike
-> flevbl.Phys
<<JobFields>>
%}

classdef FleSpikeSets < dj.Relvar
    properties(Constant)
        table = dj.Table('jobs.FleSpikeSets')
    end
    methods
        function self = FleSpikeSets(varargin)
            self.restrict(varargin) 
        end
    end
end
