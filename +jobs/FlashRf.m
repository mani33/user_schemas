%{
jobs.FlashRf(manual)   # job to populate spike
-> fle.BinnedSpikeSets
<<JobFields>>
%}

classdef FlashRf < dj.Relvar
    properties(Constant)
        table = dj.Table('jobs.FlashRf')
    end
    methods
        function self = FlashRf(varargin)
            self.restrict(varargin) 
        end
    end
end
