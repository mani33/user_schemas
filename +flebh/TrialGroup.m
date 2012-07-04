% flebh.TrialGroup - Subset of FlashLagExperiment or FlashLagExpHuman sessions

%{
flebh.TrialGroup (computed) # my newest table
-> stimulation.StimTrialGroup
-----

%}

classdef TrialGroup < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flebh.TrialGroup')
    end
    properties
        popRel = (stimulation.StimTrialGroup - acq.StimulationIgnore) & ...
            acq.Stimulation('exp_type like ''FlashLagExpHum'' and correct_trials >= 100')...
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
            makeTuples(flebh.StimConstants,key)
            makeTuples(flebh.Trials,key)
        end
    end
end
