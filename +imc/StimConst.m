%{
imc.StimConst (computed) # my newest table
-> imc.Stim
-----
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
im_center_x               : smallint unsigned             # center of image
im_center_y               : smallint unsigned             # no comments
im_size : tinyblob                      # no comments
im_vignette_width: smallint unsigned # imageVignetteWidthPix
mean_iti: double # mean intertrial time
iti_std: double # stand deviation of iti
post_stim_fixation_time: double # fixation time after stim offset
rand_generator: varchar(15) # random number generator type
im_tile_size_pix: double # image tiling to smooth the edges
coh_start_amb: double # ambiguous image first frame coherence
coh_end_amb: double # coh end
coh_start_supth: double # supth starting coh
coh_end_supth: double # supth end coh
coh_fn_amb: varchar(20) # function used to generate coh across rampsteps
coh_fn_supth:varchar(20) # fn for supth
root_coh_fn_order: double # order of root function
power_coh_fn_expo: double # exponent of power fun
im_for_avg_amp_sp: blob # images ids used for avg power spectrum
normalize_spat_freq : tinyint unsigned # was spatial freq normalized across all images?
rand_seed_data: blob # random seed data for phase scrmbling for each image
resolution_x=1600           : smallint unsigned             # monitor width in pix
resolution_y=1200           : smallint unsigned             # monitor height in pix
ua_mon_br: double # unambigous monkey background replaced
ua_hum_br: double # bla
am_mon: double # ambigous monkey
am_hum: double # bla
dynamic_stim_times: blob # dynamic part of the movie 
static_stim_times: blob # static part
n_frames_per_bufferswap: double # number of frames for each bufferswap
%}

classdef StimConst < dj.Relvar
    methods
        function self = StimConst(varargin)
            self.restrict(varargin)
        end
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            sc = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            t = key;
            t.monitor_type = 'CRT';
            t.bg_color_r = sc.bgColor(1);
            t.bg_color_g                  = sc.bgColor(2);
            t.bg_color_b                   = sc.bgColor(3);
            t.fix_spot_color  = sc.fixSpotColor;
            t.fix_spot_location           = sc.fixSpotLocation;
            t.fix_spot_size               =sc.fixSpotSize;
            t.passive                     =sc.passive;
            t.monitor_size_x              =sc.monitorSize(1);
            t.monitor_size_y     =sc.monitorSize(2);
            t.monitor_distance = sc.monitorDistance;
            t.monitor_center_x = sc.monitorCenter(1);
            t.monitor_center_y = sc.monitorCenter(2);
            t.im_center_x      = sc.imageCenter(1);
            t.im_center_y      = sc.imageCenter(2);
            t.im_size = sc.imageSize;
            t.im_vignette_width = sc.imageVignetteWidthPix;
            t.mean_iti = sc.meanIntertrialTime;
            t.iti_std = sc.intertrialTimeStd;
            t.post_stim_fixation_time =sc.postStimFixationTime;
            t.rand_generator = sc.randGenerator{:};
            t.im_tile_size_pix = sc.imageTileSizePix;
            t.coh_start_amb = sc.cohStartAmb;
            t.coh_end_amb = sc.cohEndAmb;
            t.coh_start_supth=sc.cohStartSupth;
            t.coh_end_supth = sc.cohEndSupth;
            t.coh_fn_amb=sc.cohFunctionAmb{:};
            t.coh_fn_supth=sc.cohFunctionSupth{:};
            t.root_coh_fn_order=sc.rootCohFcnOrder;
            t.power_coh_fn_expo=sc.powerCohFcnExponent;
            t.im_for_avg_amp_sp=sc.imagesForAvgAmpSpec;
            t.normalize_spat_freq=sc.normalizeSpatialFreq;
            t.rand_seed_data=sc.randomSeedData;
            t.resolution_x = sc.resolution(1);
            t.resolution_y = sc.resolution(2);
            t.ua_mon_br = sc.uaMonBr;
            t.ua_hum_br = sc.uaHumBr;
            t.am_mon = sc.amMon;
            t.am_hum = sc.amHum;
            t.dynamic_stim_times = sc.dynamicStimTimeForRampSteps;
            t.static_stim_times = sc.staticStimTimeForRampSteps;
            t.n_frames_per_bufferswap = sc.nFramesPerBufferSwap;
            self.insert(t)
        end
    end
    
end