%{
flevbl.MovStats (computed) # my newest table
-> flevbl.BarGrayLevels
-> flevbl.SpikeSets
-> flevbl.MovStatParams
-> flevbl.DxVals
-----

responsive_0 = 0: boolean # is the neuron visually responsive for direction 0
inhib_0 = 0: boolean # blah
excit_0 = 0: boolean # blah
base_fr_0 = 0: double # base firing rate
resp_fr_0 = 0: double # firing rate at the response window
p_0 = 1: double # least p-value after Bonferroni correction
responsive_1 = 0: boolean # is the neuron visually responsive
inhib_1 = 0: boolean # blah
excit_1 = 0: boolean # blah
base_fr_1 = 0: double # base firing rate
resp_fr_1 = 0: double # firing rate at the response window
p_1 = 1: double # least p-value after Bonferroni correction

movstats_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef MovStats < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.MovStats')
        popRel = (flevbl.BarGrayLevels*flevbl.SpikeSets*flevbl.MovStatParams*flevbl.DxVals) & flevbl.Traj
    end
    
    methods
        function self = MovStats(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        function makeTuples(self, key)
            nDir = 2;
            d = [0 1];
            for iDir = 1:nDir
                dir = d(iDir);
                tr = fetch(flevbl.Traj(key,sprintf('direction = %u and bar_color_r = %u and mov_in_rf = 1 and flash_shown = 0 and mov_shown = 1',...
                    dir,key.bar_gray_level)),'*');
                rfc = fetch1(rf.FitAvg(ephys.Spikes(key),'map_type_num = 3'),'cen_x');
                if ~isnan(rfc)
                    % Find time at which the trajectory crosses the receptive field
                    % center
                    [~,ind] = min(abs(tr.sx - rfc));
                    
                    % Assume a motion response onset latency of 50 ms
                    LAT = 75;
                    t0 = tr.t(ind) + LAT;
                    
                    bwin = [0 key.base_win];
                    rwin = [-key.resp_win key.resp_win]/2 + t0;
                    overlap = (rwin(2)-bwin(1)) < (key.base_win+key.resp_win);
                    if overlap
                        continue
                    end
%                     assert(overlap==1,'base and resp windows overlap')
                    
                    % Get stimulus in the receptive field arrangement
                    qs = sprintf('direction = %u and bar_color_r = %u and flash_in_rf=0 and flash_shown=0 and mov_shown=1',...
                        dir,key.bar_gray_level);
                    
                    rf_in_cond = fetch1(flevbl.StimCenProxCond(key,qs),'cond_idx');
                    cs = sprintf('cond_idx=%u',rf_in_cond);
                    
                    
                    % Get spike times
                    trialSpikes = fetchn(flevbl.SubTrialSpikes(key) & flevbl.SubTrials(key,cs)-flevbl.SubTrialsIgnore,'spike_times');
                    
                    % Get spike counts in baseline and response windows
                    bsc = cellfun(@(x) length(find(x >= bwin(1) & x < bwin(2))), trialSpikes);
                    rsc = cellfun(@(x) length(find(x >= rwin(1) & x < rwin(2))), trialSpikes);
                    
                    key.(sprintf('base_fr_%u',dir)) = mean(bsc)*1000/key.base_win;
                    key.(sprintf('resp_fr_%u',dir)) = mean(rsc)*1000/key.resp_win;
                    
                    [h,p] = ttest(bsc,rsc);
                    if ~isnan(h) && h
                        key.(sprintf('responsive_%u',dir)) = true;
                        key.(sprintf('p_%u',dir)) = p;
                        if rsc > bsc
                            key.(sprintf('excit_%u',dir)) = true;
                        else
                            key.(sprintf('inhib_%u',dir)) = true;
                        end
                    end
                end
            end
            self.insert(key)
        end
    end
end
