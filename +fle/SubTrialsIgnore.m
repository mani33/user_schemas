%{
fle.SubTrialsIgnore (manual) # subtrials to ignore
-> fle.SubTrials

-----
reason: blob # reason for ignoring the subtrials
subtrialsignore_ts = CURRENT_TIMESTAMP: timestamp  # do not edit

%}

classdef SubTrialsIgnore < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.SubTrialsIgnore')
    end
    methods 
        function self = SubTrialsIgnore(varargin)
            self.restrict(varargin{:})
        end
    end
end
