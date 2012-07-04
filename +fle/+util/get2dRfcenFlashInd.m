function rf_cen_flash_ind = get2dRfcenFlashInd(eKeys, offsetMaxPix)
% function rf_cen_flash_ind = get2dRfcenFlashInd(eKeys,offsetMaxPix)
%
% Using dotmapping, finds the rf center and gives the flash location that is closest to
% the rf center. Input ekeys should be from Flash Lag Experiment

nKeys = length(eKeys);
rf_cen_flash_ind = nan(1,nKeys);


for iKey = nKeys
    key = eKeys(iKey);
    rfKey = fetch1(fle.DotmapLink(key),'dotmap_key');
    
    if ~isempty(rfKey)
        pix_per_deg = fetch1(stim.PixPerDeg(rfKey),'pix_per_deg');
        rf_cen_x_deg = fetch1(rf.FitAvg(rfKey,'map_type_num=3'),'cen_x');
        [flash_loc_ind flash_loc_pix] = fetchn(fle.RelFlashCenX(key),'flash_location',...
            'rel_to_mon_cen');
        [flash_loc_ind ind] = sort(flash_loc_ind);
        flash_loc_deg = flash_loc_pix(ind)/pix_per_deg;
        
        if rf_cen_x_deg > flash_loc_deg(1) && rf_cen_x_deg < flash_loc_deg(end)
            offsets = abs(flash_loc_deg - rf_cen_x_deg);
            mv = min(offsets);
            if mv <= offsetMaxPix/pix_per_deg
                minValInd = find(offsets==mv);
                nMinVals = length(minValInd);
                if nMinVals > 1
                    rp = randperm(nMinVals);
                    rf_cen_flash_ind(iKey) = flash_loc_ind(minValInd(rp(1)));
                end
            end
        end
    end
end






% 
% 
% 
% 
% 
% for iKey = 1:nKeys
%     key = eKeys(iKey);
%     dmRv = acq.Sessions(key) * acq.Stimulation('exp_type = "DotMappingExperiment"');
%     rfRv = rf.SpikeSets(dmRv,sprintf('unit_id = %u',key.unit_id));
%     
%     if count(rfRv)==1
%         
%         % Get rf center_x in degrees for average map for Bright+Dark
%         rf_cen_x_deg = fetch1(rf.FitAvg(fetch(rfRv),'map_type_num=3'),'cen_x');
%         
%         % Get Flash Lag Experiment and find flash location closest to rf center
%         cond = fetch(fle.StimCond(key),'*');
%         const = fetch(fle.StimConstants(key),'*');
%         
%         % Get stimulus in the receptive field arrangement
%         cond_idx = fetchn(fle.StimCenProxCond(key,...
%             'flash_in_rf=1 and flash_shown=1 and mov_shown=0'),'cond_idx');
%         locs = [cond(cond_idx).flash_location];
%         nLocs = length(cond_idx);
%         flash_cen_x_pix = nan(1,nLocs);
%         for iLoc = 1:nLocs
%             cen = fetch1(fle.SubTrials(key,sprintf('cond_idx=%u',cond_idx(iLoc))),...
%                 'flash_centers',1);
%             flash_cen_x_pix(iLoc) = cen{:}(1);
%         end
%         
%         % Compute flash_center_x in degrees
%         distX = flash_cen_x_pix - const.monitor_center_x;
%         flash_cen_x_deg = pixels2degrees(distX, const.monitor_distance, const.resolution_x, ...
%             const.monitor_size_x);
%         pixPerDeg = degrees2pixels(1,const.monitor_distance, const.resolution_x, ...
%             const.monitor_size_x);
%         % Find the closest bar location to the rf center
%         offsets = abs(flash_cen_x_deg - rf_cen_x_deg);
%         minOffset = min(offsets);
%         
%         % If more than 1 min value found, take one randomly
%         cenLoc = locs(offsets==minOffset);
%         nMin = length(cenLoc);
%         if nMin > 1
%             rp = randperm(nMin);
%             cenLoc = cenLoc(rp(1));
%         end
%         if minOffset <= offsetMaxPix/pixPerDeg
%             rf_cen_flash_ind(iKey) = cenLoc;
%         end
%     end
% end