% flebm.StimConstants - my newest table
% I will explain what my table does here

%{
flebm.StimConstants (computed) # my newest table

-> flebm.TrialGroup
---
bg_color_r                  : tinyint unsigned              # r component of rgb
bg_color_g                  : tinyint unsigned              # g component of rgb
bg_color_b                  : tinyint unsigned              # b component of rgb
fix_spot_color              : tinyblob                      # no comments
fix_spot_location           : tinyblob                      # no comments
fix_spot_size               : tinyblob                      # no comments
monitor_size_x              : smallint unsigned             # no comments
monitor_size_y              : smallint unsigned             # no comments
monitor_distance            : double                        # no comments
monitor_center_x            : smallint unsigned             # no comments
monitor_center_y            : smallint unsigned             # no comments
flash_offsets               : blob                          # blah
offset_threshold            : smallint                      # blah
flash_locations             : blob                          # blah
bar_color_r                 : smallint unsigned             # red component of rgb
bar_color_g                 : smallint unsigned             # green component of rgb
bar_color_b                 : smallint unsigned             # blue component of rgb
bar_size_x                  : smallint unsigned             # no comments
bar_size_y                  : smallint unsigned             # no comments
fix_hold_time               : smallint unsigned             # blah
resolution_x=1600           : smallint unsigned             # monitor width in pix
resolution_y=1200           : smallint unsigned             # monitor height in pix
gamma_table=null            : mediumblob                    # blah
luminance_table=null        : mediumblob                    # lum tab
hostname=null               : varchar(250)                  # blah
start_time                  : double                        # no comments
end_time                    : double                        # no comments
folder                      : varchar(250)                  # no comments
date = Null                 : date                          # datevalue
%}

classdef StimConstants < dj.Relvar
    
    properties(Constant)
        table = dj.Table('flebm.StimConstants')
    end
    
    methods
        function self = StimConstants(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            c = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            key.bg_color_r = c.bgColor(1);
            key.bg_color_g = c.bgColor(2);
            key.bg_color_b = c.bgColor(3);
            key.fix_spot_color = c.fixSpotColor;
            key.fix_spot_location = c.fixSpotLocation;
            key.fix_spot_size = c.fixSpotSize;
            key.monitor_size_x = c.monitorSize(1);
            key.monitor_size_y = c.monitorSize(2);
            key.monitor_distance = c.monitorDistance;
            key.monitor_center_x = c.monitorCenter(1);
            key.monitor_center_y = c.monitorCenter(2);
            key.flash_offsets = c.flashOffsets;
            key.flash_locations = c.flashLocations;
            key.offset_threshold = c.offsetThreshold;
            key.bar_color_r = c.barColor(1);
            key.bar_color_g = c.barColor(2);
            key.bar_color_b = c.barColor(3);
            key.bar_size_x = c.barSize(1);
            key.bar_size_y = c.barSize(2);
            key.fix_hold_time = c.fixHoldTime;
            if isfield(c,'date')
            key.date = c.date(1:10);
            end
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
            key = util.addFieldIfExists(key,c,'lightAdaptMin','lightAdaptMin');
            

            self.insert(key)
        end
    end
end
