%{
jobs.SubTrialJobs(manual)   # job to populate subtrial based tables
-> flevbl.TrialGroup
<<JobFields>>
%}

classdef SubTrialJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('jobs.SubTrialJobs')
    end
    methods
        function self = SubTrialJobs(varargin)
            self.restrict(varargin) 
        end
    end
end
