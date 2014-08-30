%{
imc.StimCond (computed) # my newest table
-> imc.Stim
cond_idx        : smallint unsigned     # condition index for stimulus
---
learning_sess                : varchar(20)                   # rampup/down
ramp_step                    : tinyint                       # rampup or down block number
image_class                  : varchar(20)                   # amMon/amHum/uaMonBr/uaHumBr
image_type                   : varchar(20)                   # ambiguous/supth
image_num                    : int unsigned                  # imageId
dynamic_stim_time             : double # movie time of each ramp step
static_stim_time:           double # for cue static image was used at end
%}

classdef StimCond < dj.Relvar
    methods
        function self = StimCond(varargin)
            self.restrict(varargin)
        end
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            cc = fetch(stimulation.StimConditions(key),'condition_info');
            sc = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            nCond = length(cc);
            dst = sc.dynamicStimTimeForRampSteps;
            sst = sc.staticStimTimeForRampSteps;
            for iCond = 1:nCond
                c = cc(iCond).condition_info;
                key.cond_idx = c.cond_idx;
                key.learning_sess = c.learningSess;
                key.ramp_step = c.rampStep;
                key.image_class = c.imageClass;
                key.image_type = c.imageType;
                key.image_num = c.imageNum;
                key.dynamic_stim_time = dst(c.rampStep);
                key.static_stim_time = sst(c.rampStep);
                self.insert(key)
            end
        end
    end
    
end