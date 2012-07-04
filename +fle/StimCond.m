% fle.StimCond - my newest table
% I will explain what my table does here

%{
fle.StimCond (computed) # my newest table

-> fle.TrialGroup
cond_idx        : smallint unsigned     # condition index for stimulus
---
is_flash                    : tinyint                       # if flash trial
is_moving                   : tinyint                       # if moving trial
is_stop=null                : tinyint                       # is stop condition
is_init=null                : tinyint                       # if flash init condition is used
flash_location=null         : smallint unsigned             # flash location index
bar_color                   : tinyblob                      # bar color
trajectory_angle            : smallint                      # traj angle
direction=null              : tinyint                       # right or left direction
dx=null                     : smallint unsigned             # change in pixels per frame
arrangement=null            : tinyint                       # blah
%}

classdef StimCond < dj.Relvar
    
    properties(Constant)
        table = dj.Table('fle.StimCond')
    end
    
    methods
        function self = StimCond(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            cc = fetch(stimulation.StimConditions(key),'condition_info');
            nCond = length(cc);
            
            for iCond = 1:nCond
                tuple = key;
                try
                    tuple.is_flash = cc(iCond).condition_info.isFlash;
                    tuple.is_moving = cc(iCond).condition_info.isMoving;
                catch % 4 sessions from Hulk were from FlePhysExperiment with different field names
                    tuple.is_flash = cc(iCond).condition_info.isFlashTrial;
                    tuple.is_moving = cc(iCond).condition_info.isMovingTrial;
                end
                tuple = util.addFieldIfExists(tuple,cc(iCond).condition_info,'isStop','is_stop');
                tuple = util.addFieldIfExists(tuple,cc(iCond).condition_info,'isInit','is_init');
                
                tuple.flash_location = cc(iCond).condition_info.flashLocation;
                tuple.bar_color = cc(iCond).condition_info.barColor;
                tuple.trajectory_angle = cc(iCond).condition_info.trajectoryAngle;
                
                tuple = util.addFieldIfNotNan(tuple,'direction',cc(iCond).condition_info.direction);
                tuple = util.addFieldIfNotNan(tuple,'dx',cc(iCond).condition_info.dx);
                tuple = util.addFieldIfExists(tuple,cc(iCond).condition_info,'arrangement');
               
                tuple.cond_idx = cc(iCond).condition_num;
                self.insert(tuple);
            end            
        end
    end
end
