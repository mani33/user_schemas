%{
jobs.BarRf(manual)   # job to populate spike
-> flevbl.BinnedSpikeSets
<<JobFields>>
%}

classdef BarRf < dj.Relvar
    properties(Constant)
        table = dj.Table('jobs.BarRf')
    end
    methods
        function self = BarRf(varargin)
            self.restrict(varargin) 
        end
    end
end
