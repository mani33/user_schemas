%{
flebh.Trials (computed) # my newest table

-> flebh.TrialGroup
trial_num       : int                   # trial number
---
acquire_fixation_time       : smallint unsigned             # blah
bar_locations=null          : blob                          # bla
condition                   : smallint unsigned             # blah
correct_response            : tinyint                       # blah
delay_time                  : double                        # time before the monkey cannot respond
eye_control                 : tinyint                       # blah
eye_params                  : blob                          # blah
fixation_radius             : smallint unsigned             # blah
flash_duration=null         : smallint unsigned             # flash duration frames
flash_location              : smallint                      # blah
flash_offset                : smallint                      # blah
flash_rect=null             : tinyblob                      # blah
hold_fixation_time          : smallint unsigned             # blah
intertrial_time             : double                        # blah
lag_prob                    : double                        # lagging prob
move_dir=null               : smallint unsigned             # blah
move_prob                   : smallint unsigned             # blah
moving_location=null        : smallint unsigned             # blah
response_time               : double                        # blah
speed                       : smallint unsigned             # blah
swap_times=null             : blob                          # blah
sync=null                   : blob                          # blah
trajectory_angle=0          : smallint                      # in deg
trajectory_center_x         : smallint                      # blah
trajectory_center_y         : smallint                      # blah
trajectory_length           : smallint                      # blah
valid_trial                 : tinyint                       # blah
flash_bar_color_r           : smallint unsigned             # red component of rgb
flash_bar_color_g           : smallint unsigned             # green component of rgb
flash_bar_color_b           : smallint unsigned             # blue component of rgb
mov_bar_color_r             : smallint unsigned             # red component of rgb
mov_bar_color_g             : smallint unsigned             # green component of rgb
mov_bar_color_b             : smallint unsigned             # blue component of rgb
%}

classdef Trials < dj.Relvar
    
    properties(Constant)
        table = dj.Table('flebh.Trials');
    end
    
    methods
        function self = Trials(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            
            tp = fetch(stimulation.StimTrials(key),'trial_params');
            cp = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            cond = fetch(stimulation.StimConditions(key),'*');
            tp = [tp.trial_params];
            nTrials = length(tp);
            tuples = repmat(key,nTrials,1);
            for iTrial = 1:nTrials
                tuples(iTrial).trial_num = iTrial;
                tuples(iTrial).acquire_fixation_time = tp(iTrial).acquireFixationTime;
                tuples(iTrial).bar_locations = tp(iTrial).barLocations;
                tuples(iTrial).condition = tp(iTrial).condition;
                tuples(iTrial).correct_response = tp(iTrial).correctResponse;
                
                tuples(iTrial).delay_time = tp(iTrial).delayTime;
%                 tuples(iTrial).exp_mode = tp(iTrial).expMode;
                tuples(iTrial).eye_control = tp(iTrial).eyeControl;
                tuples(iTrial).eye_params = tp(iTrial).eyeParams;
                tuples(iTrial).fixation_radius = tp(iTrial).fixationRadius;
                
                if isfield(tp,'flashDuration')
                tuples(iTrial).flash_duration = tp(iTrial).flashDuration;
                end
                tuples(iTrial).flash_location = tp(iTrial).flashLocation;
                tuples(iTrial).flash_offset = tp(iTrial).flashOffset;
                tuples(iTrial).flash_rect = tp(iTrial).flashRect;
                tuples(iTrial).hold_fixation_time = tp(iTrial).holdFixationTime;
                
                tuples(iTrial).intertrial_time = tp(iTrial).intertrialTime;
                tuples(iTrial).lag_prob = tp(iTrial).lagProb;
                tuples(iTrial).move_dir = tp(iTrial).moveDir;
                tuples(iTrial).move_prob = tp(iTrial).moveProb;
                
                tuples(iTrial).moving_location = tp(iTrial).movingLocation;
                tuples(iTrial).response_time = tp(iTrial).responseTime;
                
                if isfield(tp,'speed')
                    tuples(iTrial).speed = tp(iTrial).speed;
                else
                    tuples(iTrial).speed = cp.speed;
                end
                cc = cond(tp(iTrial).condition).condition_info;
                
                if isfield(cond,'barCenYflashMov')
                    tuples(iTrial).trajectory_center_y = cc.barCenYflashMov(2);
                    tuples(iTrial).trajectory_center_x = cp.trajCenX;
                    tuples(iTrial).flash_center_y = cc.barCenYflashMov(1);
                else
                    tuples(iTrial).trajectory_center_x = tp(iTrial).trajectoryCenter(1);
                    tuples(iTrial).trajectory_center_y = tp(iTrial).trajectoryCenter(2);
                end
                
                if isfield(cp,'trajectoryLength')
                    tuples(iTrial).trajectory_length = cp.trajectoryLength;
                else
                    tuples(iTrial).trajectory_length = tp(iTrial).trajectoryLength;
                end
                
                if isfield(cp,'barColor')
                    tuples(iTrial).flash_bar_color_r = cp.barColor(1);
                    tuples(iTrial).flash_bar_color_g = cp.barColor(2);
                    tuples(iTrial).flash_bar_color_b = cp.barColor(3);
                    tuples(iTrial).mov_bar_color_r = cp.barColor(1);
                    tuples(iTrial).mov_bar_color_g = cp.barColor(2);
                    tuples(iTrial).mov_bar_color_b = cp.barColor(3);
                else
                    tuples(iTrial).flash_bar_color_r = cc.barGrayLevelFlashMov(1);
                    tuples(iTrial).flash_bar_color_g = cc.barGrayLevelFlashMov(1);
                    tuples(iTrial).flash_bar_color_b = cc.barGrayLevelFlashMov(1);
                    tuples(iTrial).mov_bar_color_r = cc.barGrayLevelFlashMov(2);
                    tuples(iTrial).mov_bar_color_g = cc.barGrayLevelFlashMov(2);
                    tuples(iTrial).mov_bar_color_b = cc.barGrayLevelFlashMov(2);
                end

                tuples(iTrial).swap_times = tp(iTrial).swapTimes;
                tuples(iTrial).sync = tp(iTrial).sync;
                if isfield(tp,'trajectoryAngle')
                    tuples(iTrial).trajectory_angle = tp(iTrial).trajectoryAngle;
                end
                tuples(iTrial).valid_trial = tp(iTrial).validTrial;
            end
            self.insert(tuples)
        end
    end
end
