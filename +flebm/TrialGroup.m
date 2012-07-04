% flebm.TrialGroup - Subset of FlashLagExperiment or FlashLagExpHuman sessions

%{
flebm.TrialGroup (computed) # my newest table
-> stimulation.StimTrialGroup
-----

%}

classdef TrialGroup < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flebm.TrialGroup')
    end
    properties
        popRel = (stimulation.StimTrialGroup - acq.StimulationIgnore) & ...
            acq.Stimulation('exp_type like ''FlashLagExperiment'' and correct_trials >= 500')...
            - acq.SessionsIgnore;
    end
    
    methods
        function self = TrialGroup(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % Populate subtables
            makeTuples(flebm.StimConstants,key)
            makeTuples(flebm.Trials,key)
        end
    end
end
