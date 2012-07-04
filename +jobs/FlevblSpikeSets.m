%{
jobs.FlevblSpikeSets(manual)   # job to populate spike
-> flevbl.Phys
<<JobFields>>
%}

classdef FlevblSpikeSets < dj.Relvar
    properties(Constant)
        table = dj.Table('jobs.FlevblSpikeSets')
    end
    methods
        function self = FlevblSpikeSets(varargin)
            self.restrict(varargin) 
        end
    end
end
