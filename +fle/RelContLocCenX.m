%{
fle.RelContLocCenX (computed) # my newest table
-> fle.TrialGroup
-> vstim.PixPerDeg

cond_idx        : smallint unsigned     # condition index for stimulus
-----
matched_flash_location : smallint unsigned # location index corresponding to bar mappping
rel_to_mon_cen_pix: smallint  # bar center x in pixels relative to monitor center
rel_to_mon_cen_deg: double  # bar center x in deg relative to monitor center
rel_to_stim_cen_pix: smallint  # bar center x in pixels relative to stim center
rel_to_stim_cen_deg: double  # bar center x in deg relative to stim center
%}
% The whole reason for this table is that the number of flash locations were different
% from the locations where the motion trajectories initiated or terminated in the special
% set of sessions for recording flash initiated and terminated conditions. The bar
% locations used for showing flashes and to initiate or terminate motion trajectories were
% all started with index 1. Because of this, a bar location will end up getting different
% indices for flash condition and motion conditions. Here we create a lookup table to go
% to the flash location index from moving bar initiation or termination location. Such a
% headache!! I should have corrected for this in the original stimulation code itself.

classdef RelContLocCenX < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.RelContLocCenX')
        popRel = fle.TrialGroup & fle.StimConstants('flash_init=1 and flash_stop =1 and flash_reverse = 1') ...
            & vstim.PixPerDeg  % !!! update the populate relation
    end
    methods
        function self = RelContLocCenX(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)
        
        function makeTuples(self, key)
            cond= fetch(fle.StimCond(key),'*');
            mon_cen_x = fetch1(fle.StimConstants(key),'monitor_center_x');
            stim_cen_x = fetch1(fle.StimConstants(key),'stim_center_x');
            ppd = fetch1(vstim.PixPerDeg(key),'pix_per_deg');
            isSelCond = [cond.is_flash]==1;
            flash_locs = [cond(isSelCond).flash_location];
            sel_cond_idx = [cond(isSelCond).cond_idx];
            flash_centers = arrayfun(@(c) fetch1(fle.SubTrials(key,sprintf('cond_idx=%u',c)),...
                'flash_centers',1),sel_cond_idx);
            flash_centers = [flash_centers{:}];
            flash_centers_x = flash_centers(1,:);
            
            % Get bar locations corresponding to the first and last position of
            % flash-initiated and flash-terminated motion trajectories respectively.
            init_idx = find([cond.is_init]==1);
            stop_idx = find([cond.is_stop]==1);
            reverse_idx = find([cond.is_reverse]);
            
            % make one vector telling init (=1) , stop (=2) amd reverse (=3)
            sel_cond_idx = [init_idx stop_idx reverse_idx];
            sel_cond = cond(sel_cond_idx);
            n_cond = length(sel_cond);
            tuples = repmat(key,1,n_cond);
                        
            for iCond = 1:n_cond
                % Pick one subtrial and get trajectory bar locations
                bar_cen = cell2mat(fetch1(fle.SubTrials(key,sprintf('cond_idx=%u',sel_cond(iCond).cond_idx)),'bar_centers',1));
                if ismember(sel_cond(iCond).cond_idx, init_idx)
                    bar_cen_x = bar_cen(1,1);
                elseif ismember(sel_cond(iCond).cond_idx, stop_idx) % stop condition - take the last position
                    bar_cen_x = bar_cen(1,end);
                elseif ismember(sel_cond(iCond).cond_idx, reverse_idx) % reverse condition - take middle position
                    assert(mod(length(bar_cen),2)==1, 'trajectory should have odd number of positions')
                    mp = (length(bar_cen)+1)/2;
                    bar_cen_x = bar_cen(1,mp);
                end
                % First find the matching flash location-x
                loc = unique(flash_locs(flash_centers_x==bar_cen_x));
                assert(length(loc)==1,'multiple physical locations for the same flash location index')
                tuples(iCond).cond_idx = sel_cond(iCond).cond_idx;
                tuples(iCond).matched_flash_location = loc;
                tuples(iCond).rel_to_mon_cen_pix = bar_cen_x-mon_cen_x;
                tuples(iCond).rel_to_mon_cen_deg = (bar_cen_x-mon_cen_x)/ppd;
                tuples(iCond).rel_to_stim_cen_pix = bar_cen_x-stim_cen_x;
                tuples(iCond).rel_to_stim_cen_deg = (bar_cen_x-stim_cen_x)/ppd;
            end
            self.insert(tuples)
        end
    end
end
