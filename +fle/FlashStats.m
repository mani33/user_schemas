%{
fle.FlashStats (computed) # my newest table
-> fle.BarGrayLevels
-> fle.FlashStatParams
-> fle.SpikeSets

-----
responsive = 0: boolean # is the neuron visually responsive
inhibitory = 0: boolean # blah
excitatory = 0: boolean # blah
base_fr: double # base firing rate
resp_fr: double # firing rate at the response window
p_min = null: double # least p-value after Bonferroni correction
flashstats_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef FlashStats < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('fle.FlashStats')
		popRel = fle.BarGrayLevels*fle.FlashStatParams*fle.SpikeSets  % !!! update the populate relation
	end

	methods
		function self = FlashStats(varargin)
			self.restrict(varargin{:})
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            tup = key;
            % Compute bin_width
            nFlash = fetch1(fle.StimConstants(key),'num_flash_locs_barmap');
           
            % Go to each flash location and get mean firing rate
            % We will only consider 'single' conditions: ie. no combined flash condition
            qs = sprintf('flash_in_rf = 1 and mov_shown = 0 and bar_color_r = %u',key.bar_gray_level);
            flash_cond = sort(fetchn(fle.StimCenProxCond(key,qs),'cond_idx'));
            nFlashCond = length(flash_cond);
            assert(nFlashCond==nFlash,'Number of flashes wrong!')
           
            temp = struct;
%             % Make use of receptive field center estimation to restrict the flash
%             % locations for statistics
%             rfrv = rf.FitAvg(ephys.Spikes(key),'map_type_num = 3');
%             rfve = rf.VarExp(ephys.Spikes(key),'map_type_num = 3');
%             brfve = fle.BarRfVarExp(ephys.Spikes(key),'bar_gray_level = 255');
            sel_locs = 1:nFlash;
%             if count(rfve)==1
%                 rf_cen = fetch1(rfrv,'cen_x');
%                 % Find flash location index close to the receptive field center
%                 if fetch1(rfve,'ve') > key.rf_fit_var_exp
%                     bar_locs = sort(unique(fetchn(fle.RelFlashCenX(key),'rel_to_mon_cen_deg')));
%                     [~,ind] = min(abs(bar_locs-rf_cen));
%                     if ind > 1 && ind < nFlash-1
%                     sel_locs = [-1 0 1] + ind; 
%                     end
%                 end
%             elseif count(brfve)
%                 % Try using bar rf fit
%                 brfrv = fle.BarRfFit(key);
%                 if fetch1(brfve,'ve') > key.rf_fit_var_exp
%                     cen = round(get_center(brfrv));
%                     if cen > 1 && cen < nFlash-1
%                         sel_locs = [-1 0 1] + cen;
%                     end
%                 end
%             else
%                 disp('No good receptive field! Using all flash locs for statistics')
%             end
            nFlash = length(sel_locs);
            % Bonferroni correction
            alpha = 0.05/nFlash;
            for iFlash = 1:nFlash
                loc_ind = sel_locs(iFlash);
                cs = sprintf('cond_idx = %u',flash_cond(loc_ind));
                skeys = fetch(fle.SubTrials(key,cs)-fle.SubTrialsIgnore);
                trialSpikes = fetchn(fle.SubTrials(skeys) * fle.SubTrialSpikes(key,skeys),'spike_times');
                temp.base{iFlash} = cellfun(@(x) length(find(x >= key.base_win_start & x < 0))*1000/abs(key.base_win_start), trialSpikes);
                temp.resp{iFlash} = cellfun(@(x) length(find(x >= key.resp_win_start & x < key.resp_win_end))*1000/(key.resp_win_end - key.resp_win_start), trialSpikes);
%                 temp.base{iFlash} = cellfun(@(x) length(find(x >= key.base_win_start & x < 0)), trialSpikes);
%                 temp.resp{iFlash} = cellfun(@(x) length(find(x >= key.resp_win_start & x < key.resp_win_end)), trialSpikes);
                [temp.p(iFlash),temp.H(iFlash)] = signrank(temp.resp{iFlash},temp.base{iFlash},'alpha',alpha);
%                 [temp.H(iFlash),temp.p(iFlash)] = ttest(temp.resp{iFlash},temp.base{iFlash},'alpha',alpha);
            end
            tup.base_fr = mean(cellfun(@mean, temp.base));
            tup.resp_fr = mean(cellfun(@mean, temp.resp));
            if any(temp.H)
                tup.responsive = true;                
                if tup.resp_fr > tup.base_fr
                    tup.excitatory = true;
                elseif tup.base_fr > tup.resp_fr
                    tup.inhibitory = true;
                end
            end    
            tup.p_min = min(temp.p);
			self.insert(tup)
		end
	end
end
