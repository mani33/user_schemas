% flevbl.StimConstants - my newest table
% I will explain what my table does here

%{
flevbl.StimConstants (computed) # my newest table

-> flevbl.TrialGroup
---
monitor_type                : varchar(250)                  # LCD or CRT monitor
bg_color_r                  : tinyint unsigned              # red component
bg_color_g                  : tinyint unsigned              # green component
bg_color_b                  : tinyint unsigned              # blue component
fix_spot_color              : tinyblob                      # no comments
fix_spot_location           : tinyblob                      # no comments
fix_spot_size               : tinyblob                      # no comments
passive                     : tinyint                       # no comments
monitor_size_x              : smallint unsigned             # no comments
monitor_size_y              : smallint unsigned             # no comments
monitor_distance            : double                        # no comments
monitor_center_x            : smallint unsigned             # no comments
monitor_center_y            : smallint unsigned             # no comments
bar_color                   : tinyblob                      # no comments
bar_size_x                  : smallint unsigned             # no comments
bar_size_y                  : smallint unsigned             # no comments
stim_center_x               : smallint unsigned             # no comments
stim_center_y               : smallint unsigned             # no comments
trajectory_length           : smallint unsigned             # no comments
trajectory_angle            : double                        # no comments
num_flash_locs              : smallint unsigned             # no comments
flash_loc_distance=null     : smallint unsigned             # blah
vertical_distance=null      : smallint                      # vert dist
max_stimulus_time=null      : smallint unsigned             # blah
inter_stimulus_time=null    : smallint unsigned             # ist
post_stimulus_time=null     : smallint unsigned             # blah
flash_stop                  : tinyint                       # no comments
flash_init                  : tinyint                       # was it flash initiated condition
combined=0                  : tinyint                       # flash and moving bar together
arrangement=null            : tinyblob                      # blah
reward_prob                 : double                        # no comments
direction                   : tinyblob                      # no comments
resolution_x=1600           : smallint unsigned             # monitor width in pix
resolution_y=1200           : smallint unsigned             # monitor height in pix
gamma_table=null            : mediumblob                    # blah
luminance_table=null        : mediumblob                    # lum tab
hostname=null               : varchar(250)                  # blah
start_time                  : double                        # no comments
end_time                    : double                        # no comments
folder                      : varchar(250)                  # no comments
date                        : date                          # datevalue
num_flash_locs_barmap       : smallint unsigned             # number of bars for rf mapping
%}

classdef StimConstants < dj.Relvar
    
    properties(Constant)
        table = dj.Table('flevbl.StimConstants')
    end
    
    methods
        function self = StimConstants(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            c = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            if isfield(c,'monitorType')
                key.monitor_type = c.monitorType;
            else
                key.monitor_type = 'CRT';
            end
            key.bg_color_r = c.bgColor(1);
            key.bg_color_g = c.bgColor(2);
            key.bg_color_b = c.bgColor(3);
            key.fix_spot_color = c.fixSpotColor;
            key.fix_spot_location = c.fixSpotLocation;
            key.fix_spot_size = c.fixSpotSize;
            key.passive = c.passive;
            key.monitor_size_x = c.monitorSize(1);
            key.monitor_size_y = c.monitorSize(2);
            key.monitor_distance = c.monitorDistance;
            key.monitor_center_x = c.monitorCenter(1);
            key.monitor_center_y = c.monitorCenter(2);
            key.bar_color = c.barColor;
            key.bar_size_x = c.barSize(1);
            key.bar_size_y = c.barSize(2);
            key.stim_center_x = c.stimCenter(1);
            key.stim_center_y = c.stimCenter(2);
            key.trajectory_length = c.trajectoryLength;
            key.trajectory_angle = c.trajectoryAngle;
            key.num_flash_locs = c.numFlashLocs;
            if isfield(c,'numFlashLocsBarMap')
                key.num_flash_locs_barmap = c.numFlashLocsBarMap;
            else
                key.num_flash_locs_barmap = c.numFlashLocs;
            end
            key = util.addFieldIfExists(key,c,'flashLocDistance','flash_loc_distance');
            key = util.addFieldIfExists(key,c,'verticalDistance','vertical_distance');
            key.direction = c.direction;
            key = util.addFieldIfExists(key,c,'maxStimulusTime','max_stimulus_time');
            key = util.addFieldIfExists(key,c,'interStimulusTime','inter_stimulus_time');
            key = util.addFieldIfExists(key,c,'postStimulusTime','post_stimulus_time');
            key.flash_stop = c.flashStop;
            if isfield(c,'flashInit')
                if isnan(c.flashInit)
                    key.flash_init = 0;
                else
                    key.flash_init = c.flashInit;
                end
            end
            key = util.addFieldIfExists(key,c,'combined');
            key = util.addFieldIfExists(key,c,'arrangement');
            key.reward_prob = c.rewardProb;
            key.date = c.date(1:10);
            if isfield(c,'resolution')
                key.resolution_x = c.resolution(1);
                key.resolution_y = c.resolution(2);
            end
            key = util.addFieldIfExists(key,c,'gammaTable','gamma_table');
            key = util.addFieldIfExists(key,c,'luminanceTable','luminance_table');
            key = util.addFieldIfExists(key,c,'hostname');
            key.start_time = c.startTime;
            key.end_time = c.endTime;
            key.folder = c.folder;
            self.insert(key)
        end
    end
end
