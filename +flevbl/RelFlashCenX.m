%{
flevbl.RelFlashCenX (computed) # Conversion from flash loc index to loc in pix rel to monCen
-> flevbl.TrialGroup
flash_location : smallint unsigned # flash location index
-----
rel_to_mon_cen: smallint  # flash center x in pixels relative to monitor center
rel_to_stim_cen: smallint  # flash center x in pixels relative to stim center
%}

classdef RelFlashCenX < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.RelFlashCenX')
    end
    properties
        popRel = flevbl.TrialGroup  % !!! update the populate relation
    end
    
    methods
        function self = RelFlashCenX(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            cond= fetch(flevbl.StimCond(key),'*');
            mon_cen_x = fetch1(flevbl.StimConstants(key),'monitor_center_x');
            stim_cen_x = fetch1(flevbl.StimConstants(key),'stim_center_x');
            
            isSelCond = [cond.is_flash] & ~[cond.is_moving];
            arr = unique([cond(isSelCond).arrangement]);
            arr = arr(~isnan(arr));
            if ~isnan(arr)
                isSelCond = isSelCond & [cond.arrangement]==arr(1);
            end
            sel_cond_idx = [cond(isSelCond).cond_idx];
            flash_locs = [cond(isSelCond).flash_location];
            flash_centers = arrayfun(@(c) fetch1(flevbl.SubTrials(key,sprintf('cond_idx=%u',c)),...
                'flash_centers',1),sel_cond_idx);
            nFlash = length(sel_cond_idx);
            tuples = repmat(key,1,nFlash);
            for iFlash = 1:nFlash
                tuples(iFlash).flash_location = flash_locs(iFlash);
                tuples(iFlash).rel_to_mon_cen = flash_centers{iFlash}(1)-mon_cen_x;
                tuples(iFlash).rel_to_stim_cen = flash_centers{iFlash}(1)-stim_cen_x;
                
            end
            
            self.insert(tuples)
        end
    end
end
