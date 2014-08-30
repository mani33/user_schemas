%{
fle.FlashRespProp (computed) # my newest table
-> fle.BarGrayLevels
-> fle.FlashStatParams
-> fle.SpikeSets
-----
base_mean = 0: double # bla
base_std = 0: double # bla
resp_peak = 0: double # blah

%}

classdef FlashRespProp < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.FlashRespProp')
        popRel = ((fle.BarGrayLevels*fle.FlashStatParams*(fle.SpikeSets & (ephys.Spikes(rf.MapSets) | fle.BarRfFit)))) & ...
            fle.PsthByCond
    end
    methods
        function self = FlashRespProp(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)
        
        function makeTuples(self, key)
            tup = key;
            
            % Get rf center flash
            %             rf_cen = fetch1(rf.FitAvg(ephys.Spikes(key),'map_type_num = 3'),'cen_x');
            rf_cen = get_rf_cen(key);
            % Get flash location index
            bc = sort(fetchn(fle.RelFlashCenX(key) & fle.StimCenProxCond(key,sprintf('flash_in_rf = 1 and mov_shown = 0 and bar_color_r = %u',key.bar_gray_level)),'rel_to_mon_cen_deg'));
            bw = fetch1(fle.StimConstants(key),'bar_size_x')/mean(fetchn(vstim.PixPerDeg(key),'pix_per_deg'));
            [ds, loc_ind] = min(abs(bc-rf_cen));
            
            % Compute bin_width
            nFlash = fetch1(fle.StimConstants(key),'num_flash_locs_barmap');
            
            if ds < bw
                % We will only consider 'single' conditions: ie. no combined flash condition
                qs = sprintf('flash_in_rf = 1 and mov_shown = 0 and flash_in_rf = 1 and bar_color_r = %u',key.bar_gray_level);
                flash_cond = sort(fetchn(fle.StimCenProxCond(key,qs),'cond_idx'));
                nFlashCond = length(flash_cond);
                assert(nFlashCond==nFlash,'Number of flashes wrong!')
                
                
                cs = sprintf('cond_idx = %u',flash_cond(loc_ind));
                
                % Get mean and std of psth during baseline
                [mfr,t] = fetch1(fle.PsthByCond(key,cs)*fle.BinTimesByCond(key,cs),'mean_fr','t');
                base = mfr(t > key.base_win_start & t < 0);
                tup.base_mean = mean(base);
                tup.base_std = std(base);
                
                % Find response peak
                resp = mfr(t > key.resp_win_start & t < key.resp_win_end);
                tup.resp_peak = max(resp);
            end
            self.insert(tup)
        end
    end
    methods(Static)
        function cen_x = get_rf_cen(key)
            % cen_x = get_rf_cen(ekeys,param1,paramVal1,param2,paramVal2,...)
            %-----------------------------------------------------------------------------------------
            % GET_RF_CEN - Get 2d or 1d receptive field center_x. Two-dim rf is first used. If it is
            % not available, we resort to 1d bar map to get rf center.
            %
            % example: cen_x = get_rf_cen(ekeys)
            %
            % This function is called by:
            % This function calls:
            % MAT-files required:
            %
            % See also:
            
            % Author: Mani Subramaniyan
            % Date created: 2013-10-12
            % Last revision: 2013-10-12
            % Created in Matlab version: 8.1.0.604 (R2013a)
            %-----------------------------------------------------------------------------------------
            
            dotrf = rf.FitAvg(ephys.Spikes(key),'map_type_num = 3');
            bgl = max(fetchn(fle.BarGrayLevels(key),'bar_gray_level'));
            if count(dotrf)>=1
                cen_x = fetch1(dotrf,'cen_x');
            else
                barrf = fle.BarRfFit(key,sprintf('bar_gray_level = %u',bgl));
                n = count(barrf);
                if n == 1
                    cen_x = get_center(barrf);
                else
                    % Get the biggest bin width or longest lag time tuple
                    bw = arrayfun(@(x) fetch1(fle.BarRfFit(x),'bin_width'), fetch(barrf));
                    lag = arrayfun(@(x) fetch1(fle.BarRfFit(x),'max_lag'), fetch(barrf));
                    mx = min([10 max(bw)]);
                    mbw = find(bw==mx,1);
                    cen_x = get_center(barrf & sprintf('bin_width = %u and max_lag = %u', bw(mbw), lag(mbw)));
                end
            end
        end
    end
end
