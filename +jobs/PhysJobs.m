%{
fle.PhysJobs(manual)   # jobs run at the end of each experiment
-> fle.Phys
<<JobFields>>
%}

classdef PhysJobs < dj.Relvar
    properties(Constant)
        table = dj.Table('fle.PhysJobs')
    end
    methods
        function self = PhysJobs(varargin)
            self.restrict(varargin) 
        end
    end
end
%}