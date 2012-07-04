%{
jobs.StimGroup(manual)   # jobs run at the end of each experiment
-> acq.Stimulation
<<JobFields>>
%}

classdef StimGroup < dj.Relvar
    properties(Constant)
        table = dj.Table('jobs.StimGroup')
    end
    methods
        function self = StimGroup(varargin)
            self.restrict(varargin) 
        end
    end
end
%}