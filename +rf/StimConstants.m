%{
rf.StimConstants (computed) # my newest table

-> rf.TrialGroup
---
bg_color                    : tinyblob                      # no comments
fix_spot_color              : tinyblob                      # no comments
fix_spot_location           : tinyblob                      # no comments
fix_spot_size               : tinyblob                      # no comments
dot_color                   : tinyblob                      # 2 elem vector of two grayscale vals [0 255]
passive                     : tinyint                       # no comments
monitor_size_x=41           : smallint unsigned             # width in cm
monitor_size_y=30           : smallint unsigned             # height in cm
monitor_distance            : double                        # no comments
monitor_center_x=800        : smallint unsigned             # blah
monitor_center_y=600        : smallint unsigned             # blah
stim_center_x               : smallint unsigned             # no comments
stim_center_y               : smallint unsigned             # no comments
dot_size                    : smallint unsigned             # in pix
stim_frames                 : smallint unsigned             # number of frames a single color was shown
dot_num_x                   : smallint unsigned             # width of array of dots
dot_num_y                   : smallint unsigned             # height of array of dots
resolution_x=1600           : smallint unsigned             # blah
resolution_y=1200           : smallint unsigned             # blah
gamma_table=null            : mediumblob                    # blah
luminance_table=null        : mediumblob                    # blah
folder                      : varchar(250)                  # no comments
date                        : date                          # datevalue
%}
classdef StimConstants < dj.Relvar
    
    properties(Constant)
        table = dj.Table('rf.StimConstants')
    end
    
    methods
        function self = StimConstants(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            c = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            key.bg_color = c.bgColor;
            key.fix_spot_color = c.fixSpotColor;
            key.dot_color = c.dotColor;
            key.fix_spot_location = c.fixSpotLocation;
            key.fix_spot_size = c.fixSpotSize;
            key.passive = c.passive;
%             if isfield(c,'monitorSize')
%                 key.monitor_size_x = c.monitorSize(1);
%                 key.monitor_size_y = c.monitorSize(2);
%             end
            key.monitor_distance = c.monitorDistance;
            
            
            if isfield(c,'monitorCenter')
                key.monitor_center_x = c.monitorCenter(1);
                key.monitor_center_y = c.monitorCenter(2);
            end
            % In the old acq system, stimCenterX and stimCenterY were trial-by-trial
            % params. In the new acq system, they are constants. We are going to conver
            % the old system data to adhere to the new system
            
            if isfield(c,'stimCenterX') % new system
                
                key.stim_center_x = c.stimCenterX;
                key.stim_center_y = c.stimCenterY;
                key.dot_size = c.dotSize;
                key.stim_frames = c.stimFrames;
                key.dot_num_x = c.dotNumX;
                key.dot_num_y = c.dotNumY;
            else % old system
                
                % Make sure that all trials had the identical trial by trial stim params
                tp = fetch(stimulation.StimTrials(key),'trial_params');
                params = {'dotSize','stimCenterX','stimCenterY','stimFrames','dotNumX','dotNumY'};
                djParams = {'dot_size','stim_center_x','stim_center_y','stim_frames','dot_num_x',...
                    'dot_num_y'};
                nParams = length(params);
                nTrials = length(tp);
                for iParam = 1:nParams
                    cparam = params{iParam};
                    val = arrayfun(@(ind) tp(ind).trial_params.(cparam),1:nTrials);
                    uval = unique(val);
                    if length(uval)== 1
                        key.(djParams{iParam}) = uval;
                    else
%                         uvalRep = arrayfun(@(x) length(find(val==x)), uval);
%                         [~, ind] = max(uvalRep);
%                         selVal = uval(ind);
%                         key.(djParams{iParam}) = selVal;
                        error('%s is not same on all trials. Go and fix the original stim structure \nobtained in the DotMappingExperiment so that all trials have the same \nstimulus params, then import it into stimulation.StimTrialGroup table\n and visit this table again',cparam);
                    end
                end
            end
            
            key.date = c.date(1:10);
            if isfield(c,'resolution')
                key.resolution_x = c.resolution(1);
                key.resolution_y = c.resolution(2);
            end
            key = util.addFieldIfExists(key,c,'gammaTable','gamma_table');
            key = util.addFieldIfExists(key,c,'luminanceTable','luminance_table');
            key.folder = c.folder;
            self.insert(key)
        end
    end
end
