%{
fle.TrialGroupJobs(manual)   # jobs run at the end of each experiment
-> fle.TrialGroup
<<JobFields>>
%}

classdef TrialGroupJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('fle.TrialGroupJobs')
    end
    methods
        function self = TrialGroupJobs(varargin)
            self.restrict(varargin) 
        end
    end
end
%}