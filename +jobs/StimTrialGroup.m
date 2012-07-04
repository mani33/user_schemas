%{
jobs.StimTrialGroup(manual)   # jobs run at the end of each experiment
-> acq.Stimulation
<<JobFields>>
%}

classdef StimTrialGroup < dj.Relvar
    properties(Constant)
        table = dj.Table('jobs.StimTrialGroup')
    end
    methods
        function self = StimTrialGroup(varargin)
            self.restrict(varargin) 
        end
    end
end
%}