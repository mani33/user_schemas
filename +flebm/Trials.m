%{
flebm.Trials (computed) # my newest table

-> flebm.TrialGroup
trial_num       : int                   # trial number
---
acquire_fixation_time       : smallint unsigned             # blah
bar_locations=null          : blob                          # bla
condition                   : smallint unsigned             # blah
correct_response            : tinyint                       # blah
delay_time                  : double                        # time before the monkey cannot respond
exp_mode                    : tinyint                       # blah
eye_control=null            : tinyint                       # blah
eye_params=null             : blob                          # blah
fixation_radius=null        : int unsigned                  # blah
flash_duration              : smallint unsigned             # flash duration frames
flash_location              : smallint                      # blah
flash_offset                : smallint                      # blah
flash_rect=null             : tinyblob                      # blah
hold_fixation_time          : smallint unsigned             # blah
intertrial_time             : double                        # blah
lag_prob                    : double                        # lagging prob
max_block_size              : smallint unsigned             # number of correct trials before reward
move_dir=null               : smallint unsigned             # blah
move_prob                   : smallint unsigned             # blah
moving_location=null        : int                           # blah
no_flash_zone               : smallint unsigned             # blah
perceived_lag               : int                           # blah
rand_location               : tinyint                       # blah
response_time               : double                        # blah
reward_amount               : double                        # blah
speed                       : smallint unsigned             # blah
swap_times=null             : blob                          # blah
sync=null                   : blob                          # blah
trajectory_angle            : smallint                      # blah
trajectory_center_x         : smallint                      # blah
trajectory_center_y         : smallint                      # blah
trajectory_length           : smallint                      # blah
valid_trial                 : tinyint                       # blah
left_target=null            : tinyblob                      # left target location
right_target=null           : tinyblob                      # right target location
target_radius=null          : int unsigned                  # left target radius
%}

classdef Trials < dj.Relvar
    
    properties(Constant)
        table = dj.Table('flebm.Trials');
    end
    
    methods
        function self = Trials(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            
            tp = fetch(stimulation.StimTrials(key),'trial_params');
            tp = [tp.trial_params];
            nTrials = length(tp);
            tuples = repmat(key,nTrials,1);
            selFields =  {'moveDir','movingLocation','flashRect','barLocations'};
            nF = length(selFields);
            for iTrial = 1:nTrials
                for iField = 1:nF
                    cF = selFields{iField};
                    if isempty(tp(iTrial).(cF))
                        tp(iTrial).(cF) = NaN;
                    end
                end
                
                tuples(iTrial).trial_num = iTrial;
                tuples(iTrial).acquire_fixation_time = tp(iTrial).acquireFixationTime;
                tuples(iTrial).bar_locations = tp(iTrial).barLocations;
                tuples(iTrial).condition = tp(iTrial).condition;
                tuples(iTrial).correct_response = tp(iTrial).correctResponse;
                
                tuples(iTrial).delay_time = tp(iTrial).delayTime;
                tuples(iTrial).exp_mode = tp(iTrial).expMode;
                if isfield(tp(iTrial),'eyeControl')
                    tuples(iTrial).eye_control = tp(iTrial).eyeControl;
                end
                if isfield(tp(iTrial),'eyeParams')
                    tuples(iTrial).eye_params = tp(iTrial).eyeParams;
                end
                if isfield(tp(iTrial),'fixationRadius')
                    tuples(iTrial).fixation_radius = tp(iTrial).fixationRadius;
                end
                
                tuples(iTrial).flash_duration = tp(iTrial).flashDuration;
                tuples(iTrial).flash_location = tp(iTrial).flashLocation;
                tuples(iTrial).flash_offset = tp(iTrial).flashOffset;
                tuples(iTrial).flash_rect = tp(iTrial).flashRect;
                tuples(iTrial).hold_fixation_time = tp(iTrial).holdFixationTime;
                
                tuples(iTrial).intertrial_time = tp(iTrial).intertrialTime;
                tuples(iTrial).lag_prob = tp(iTrial).lagProb;
                tuples(iTrial).max_block_size = tp(iTrial).maxBlockSize;
                
                tuples(iTrial).move_dir = tp(iTrial).moveDir;
                tuples(iTrial).move_prob = tp(iTrial).moveProb;
                
                tuples(iTrial).moving_location = tp(iTrial).movingLocation;
                tuples(iTrial).no_flash_zone = tp(iTrial).noFlashZone;
                tuples(iTrial).perceived_lag = tp(iTrial).perceivedLag;
                tuples(iTrial).rand_location = tp(iTrial).randLocation;
                tuples(iTrial).response_time = tp(iTrial).responseTime;
                
                tuples(iTrial).reward_amount = tp(iTrial).rewardAmount;
                tuples(iTrial).speed = tp(iTrial).speed;
                tuples(iTrial).swap_times = tp(iTrial).swapTimes;
                tuples(iTrial).sync = tp(iTrial).sync;
                tuples(iTrial).trajectory_angle = tp(iTrial).trajectoryAngle;
                
                tuples(iTrial).trajectory_center_x = tp(iTrial).trajectoryCenter(1);
                tuples(iTrial).trajectory_center_y = tp(iTrial).trajectoryCenter(2);
                tuples(iTrial).trajectory_length = tp(iTrial).trajectoryLength;
                tuples(iTrial).valid_trial = tp(iTrial).validTrial;
            end
            self.insert(tuples)
        end
    end
end
