%{
jobs.SpikeSetJobs(manual)   # job to populate spike
-> sort.SetsCompleted
<<JobFields>>
%}

classdef SpikeSetJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('jobs.SpikeSetJobs')
    end
    methods
        function self = SpikeSetJobs(varargin)
            self.restrict(varargin) 
        end
    end
end
