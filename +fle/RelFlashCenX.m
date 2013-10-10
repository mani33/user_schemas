%{
fle.RelFlashCenX (computed) # Conversion from flash loc index to loc in pix rel to monCen
-> fle.TrialGroup
-> vstim.PixPerDeg
cond_idx        : smallint unsigned     # condition index for stimulus
-----
flash_location : smallint unsigned # flash location index
rel_to_mon_cen_pix: smallint  # flash center x in pixels relative to monitor center
rel_to_mon_cen_deg: double  # flash center x in deg relative to monitor center
rel_to_stim_cen_pix: smallint  # flash center x in pixels relative to stim center
rel_to_stim_cen_deg: double  # flash center x in deg relative to stim center
%}

classdef RelFlashCenX < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.RelFlashCenX')
        popRel = fle.TrialGroup & vstim.PixPerDeg  % !!! update the populate relation
    end
    methods
        function self = RelFlashCenX(varargin)
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
            nFlash = length(sel_cond_idx);
            tuples = repmat(key,1,nFlash);
            for iFlash = 1:nFlash
                tuples(iFlash).cond_idx = sel_cond_idx(iFlash);
                tuples(iFlash).flash_location = flash_locs(iFlash);
                tuples(iFlash).rel_to_mon_cen_pix = flash_centers{iFlash}(1)-mon_cen_x;
                tuples(iFlash).rel_to_mon_cen_deg = (flash_centers{iFlash}(1)-mon_cen_x)/ppd;
                tuples(iFlash).rel_to_stim_cen_pix = flash_centers{iFlash}(1)-stim_cen_x;
                tuples(iFlash).rel_to_stim_cen_deg = (flash_centers{iFlash}(1)-stim_cen_x)/ppd;
            end            
            self.insert(tuples)
        end
    end
end
