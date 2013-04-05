% flevbl.StimCond - my newest table
% I will explain what my table does here

%{
flevbl.StimCond (computed) # my newest table

-> flevbl.TrialGroup
cond_idx        : smallint unsigned     # condition index for stimulus
---
is_flash                    : tinyint                       # if flash trial
is_moving                   : tinyint                       # if moving trial
is_stop=0                   : tinyint                       # is flash stop condition
is_init=0                   : tinyint                       # is flash init condition
flash_location=null         : smallint unsigned             # flash location index
bar_color_r                 : tinyint unsigned              # bar color_R
bar_color_g                 : tinyint unsigned              # bar color_G
bar_color_b                 : tinyint unsigned              # bar color_B
trajectory_angle            : smallint                      # traj angle
traj_offset=null            : smallint                      # trajectory offset
direction                   : tinyint                       # direction of motion
dx=null                     : smallint unsigned             # change in pixels per frame
arrangement=null            : tinyint                       # blah
%}

classdef StimCond < dj.Relvar
    
    properties(Constant)
        table = dj.Table('flevbl.StimCond')
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
                tuple.bar_color_r = cc(iCond).condition_info.barColor(1);
                tuple.bar_color_g = cc(iCond).condition_info.barColor(2);
                tuple.bar_color_b = cc(iCond).condition_info.barColor(3);
                tuple.trajectory_angle = cc(iCond).condition_info.trajectoryAngle;
                
                tuple = util.addFieldIfExists(tuple,cc(iCond).condition_info,'trajOffset','traj_offset');
                % For flash only condition, set the direction to -1 instead of NaN
                curr_dir = cc(iCond).condition_info.direction;
                if logical(tuple.is_flash) && ~logical(tuple.is_moving)
                    if isnan(curr_dir)
                        curr_dir = -1;
                    end
                end
                tuple = util.addFieldIfNotNan(tuple,'direction',curr_dir);
                tuple = util.addFieldIfNotNan(tuple,'dx',cc(iCond).condition_info.dx);
                tuple = util.addFieldIfExists(tuple,cc(iCond).condition_info,'arrangement');
               
                tuple.cond_idx = cc(iCond).condition_num;
                self.insert(tuple);
            end            
        end
    end
end
