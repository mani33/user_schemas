% flebm.TrialGroup - Subset of FlashLagExperiment or FlashLagExpHuman sessions

%{
flebm.TrialGroup (computed) # my newest table
-> stimulation.StimTrialGroup
-----

%}

classdef TrialGroup < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flebm.TrialGroup')    
        popRel = (stimulation.StimTrialGroup - acq.StimulationIgnore) & ...
            acq.Stimulation('exp_type in ("FlashLagExperiment","TrialBasedExperiment") and (correct_trials + incorrect_trials)> 500')...
            - acq.SessionsIgnore;
    end
    
    methods
        function self = TrialGroup(varargin)
            self.restrict(varargin)
        end
    end
    methods (Access=protected)        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % Populate subtables
            makeTuples(flebm.StimConstants,key)
            makeTuples(flebm.Trials,key)
        end
    end
end
