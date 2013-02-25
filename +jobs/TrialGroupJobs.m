%{
flevbl.TrialGroupJobs(manual)   # jobs run at the end of each experiment
-> flevbl.TrialGroup
<<JobFields>>
%}

classdef TrialGroupJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('jobs.TrialGroupJobs')
    end
    methods
        function self = TrialGroupJobs(varargin)
            self.restrict(varargin) 
        end
    end
end
%}