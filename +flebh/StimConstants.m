% flebh.StimConstants - my newest table
% I will explain what my table does here

%{
flebh.StimConstants (computed) # my newest table

-> flebh.TrialGroup
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
flash_locations             : blob                          # blah
bar_size_x                  : smallint unsigned             # no comments
bar_size_y                  : smallint unsigned             # no comments
fix_hold_time               : smallint unsigned             # blah
resolution_x=1600           : smallint unsigned             # monitor width in pix
resolution_y=1200           : smallint unsigned             # monitor height in pix
gamma_table=null            : mediumblob                    # blah
hostname=null               : varchar(250)                  # blah
start_time                  : double                        # no comments
end_time                    : double                        # no comments
folder                      : varchar(250)                  # no comments
date = Null                 : date                          # datevalue
n_blocks                    : tinyint unsigned              # blah
%}

classdef StimConstants < dj.Relvar
    
    properties(Constant)
        table = dj.Table('flebh.StimConstants')
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
            key = util.addFieldIfExists(key,c,'hostname');
            key.start_time = c.startTime;
            key.end_time = c.endTime;
            key.folder = c.folder;
            key.n_blocks = c.nBlocks;
            self.insert(key)
        end
    end
end
