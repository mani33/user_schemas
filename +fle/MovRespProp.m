%{
fle.MovRespProp (computed) # my newest table
-> fle.BarGrayLevels
-> fle.SpikeSets
-> fle.MovStatParams
-> fle.DxVals
-----
base_mean_0 = 0: double # base firing rate
base_std_0 = 0: double # blah
resp_peak_0 = 0: double # max firing rate at the response window
base_mean_1 = 0: double # base firing rate
base_std_1 = 0: double # blah
resp_peak_1 = 0: double # max firing rate at the response window

%}

classdef MovRespProp < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.MovRespProp')
        popRel = ((fle.BarGrayLevels*fle.SpikeSets*fle.MovStatParams*fle.DxVals) & (fle.Traj | fle.TrajControls)) ...
            & fle.PsthByCond
    end
    methods
        function self = MovRespProp(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)
        
        function makeTuples(self, key)
            nDir = 2;
            d = [0 1];
            for iDir = 1:nDir
                dir = d(iDir);
                % In control sessions, we only use the continuous motion condtion to do
                % statistics ( we don't use the flash-initiated, terminated and reversed
                % conditions)
                if logical(fetch1(fle.StimConstants(key),'flash_reverse')) || logical(fetch1(fle.StimConstants(key),'flash_init'))
                    cond_idx = fetchn(fle.StimCond(key,'is_reverse = 0 and is_init = 0 and is_stop = 0') & ...
                        fle.StimCenProxCond(sprintf('direction = %u and bar_color_r = %u and mov_in_rf = 1 and flash_shown = 0 and mov_shown = 1',...
                        dir,key.bar_gray_level)),'cond_idx');
                    tr = fetch(fle.TrajControls(key,sprintf('cond_idx = %u',cond_idx)),'*');
                else
                    cond_idx = fetch1(fle.StimCenProxCond(key,sprintf('direction = %u and bar_color_r = %u and mov_in_rf = 1 and flash_shown = 0 and mov_shown = 1',...
                        dir,key.bar_gray_level)),'cond_idx');
                    tr = fetch(fle.Traj(key,sprintf('direction = %u and bar_color_r = %u and mov_in_rf = 1 and flash_shown = 0 and mov_shown = 1',...
                        dir,key.bar_gray_level)),'*');
                end
                rfc = fle.MovStats.get_rf_cen(key);
                if ~isnan(rfc)
                    % Find time at which the trajectory crosses the receptive field
                    % center
                    [~,ind] = min(abs(tr.sx - rfc));
                    
                    % Assume a motion response onset latency
                    LAT = 75;
                    t0 = tr.t(ind) + LAT;
                    
                    bwin = [-key.base_win 0];
                    rwin = [-key.resp_win key.resp_win]/2 + t0;
                    overlap = (rwin(2)-bwin(1)) < (key.base_win+key.resp_win);
                    if overlap
                        continue
                    end
                    cs = sprintf('cond_idx = %u',cond_idx);
                                        
                    % Get mean and std of psth during baseline
                    [mfr,t] = fetch1(fle.PsthByCond(key,cs)*fle.BinTimesByCond(key,cs),'mean_fr','t');
                    base = mfr(t > bwin(1) & t < bwin(2));
                    key.(sprintf('base_mean_%u',dir)) = mean(base);
                    key.(sprintf('base_std_%u',dir)) = std(base);
                    
                    % Find response peak
                    resp = mfr(t > rwin(1) & t < rwin(2));
                    key.(sprintf('resp_peak_%u',dir)) = max(resp);
                    
                end
            end
            self.insert(key)
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
