%{
imc.Stim (computed) # selected stim sessions from ImageCategorization exp
-> stimulation.StimTrialGroup
-----
# stim_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef Stim < dj.Relvar & dj.AutoPopulate
    
    properties
        popRel = (stimulation.StimTrialGroup - acq.StimulationIgnore) &...
            acq.Stimulation('exp_type like "ImageCategorization" and correct_trials >= 300')...
            - acq.SessionsIgnore
    end
    
    methods
        function self = Stim(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % populate subtables
            makeTuples(imc.StimCond,key)
            makeTuples(imc.StimConst,key)
            makeTuples(imc.Trials,key)
        end
    end
    
end