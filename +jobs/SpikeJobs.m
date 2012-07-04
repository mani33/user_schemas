%{
fle.SpikeJobs(manual)   # jobs run at the end of each experiment
-> fle.SpikeSets
<<JobFields>>
%}

classdef SpikeJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('fle.SpikeJobs')
    end
    methods
        function self = SpikeJobs(varargin)
            self.restrict(varargin) 
        end
    end
end
%}