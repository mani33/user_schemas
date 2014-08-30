%{
imc.Trials (computed) # my newest table
-> imc.Stim

trial_num     : int unsigned          # Trial number
-----
cond_idx         : smallint unsigned     # condition index of the subTrial
stim_on       : bigint unsigned       # showStimulus time
stim_off      : bigint unsigned       # endStimulus time
fix_radius: double # fixation radius pixels
eye_control: tinyint unsigned # was fixation required?
eye_params: tinyblob # eye parameters
inter_trial_time: double # iti
hold_fixation_time: double # fixation time before stim onset
correct_resp: tinyblob # correct response or not?
correct_reward_prob: double # reward prob
reward_duration : double # actual reward given in ms
%}

classdef Trials < dj.Relvar
    methods
                function self = Trials(varargin)
            self.restrict(varargin)
        end
        function makeTuples(self, key)
            %!!! compute missing fields for key here
           
            %!!! compute missing fields for key here
            td = fetch(stimulation.StimTrials(key),'*');
            td = td(logical([td.valid_trial]));
            nVtrials = length(td);
            tu = key;
            
            
            for iTrial = 1:nVtrials
                % Get substimulus onsets and offsets
                ct = td(iTrial);
                tInd = ct.trial_num;
                tn = sprintf('trial_num = %0.0f',tInd);
                onset = fetch1(stimulation.StimTrialEvents(key,tn,'event_type = ''showStimulus'''),'event_time');
                offset = fetch1(stimulation.StimTrialEvents(key,tn,'event_type = ''endStimulus'''),'event_time');
                tu.trial_num = tInd;
                tp = ct.trial_params;
                tu.cond_idx = tp.condition;
                tu.stim_on = int64(onset);
                tu.stim_off = int64(offset);
                tu.fix_radius = tp.fixationRadius;
                tu.eye_control = tp.eyeControl;
                tu.eye_params = tp.eyeParams;
                tu.inter_trial_time = tp.interTrialTime;
                tu.reward_duration = tp.rewardDuration;
                tu.hold_fixation_time = tp.holdFixationTime;
                tu.correct_resp = tp.correctResponse;
                tu.correct_reward_prob = tp.correctRewardProb;
                self.insert(tu);
            end
        end
    end
    
end