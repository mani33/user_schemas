%{
flevbl.SubTrialsIgnore (manual) # subtrials to ignore
-> flevbl.SubTrials

-----
reason: blob # reason for ignoring the subtrials
subtrialsignore_ts = CURRENT_TIMESTAMP: timestamp  # do not edit

%}

classdef SubTrialsIgnore < dj.Relvar

	properties(Constant)
		table = dj.Table('flevbl.SubTrialsIgnore')
    end
    methods 
        function self = SubTrialsIgnore(varargin)
            self.restrict(varargin{:})
        end
    end
end
