%{
fle.StRf (computed) # my newest table
-> fle.BarGrayLevels
-> fle.SpikeSets
-> fle.StRfParams

-----
space_time_map: blob # mean firing rate map
bin_cen_times: blob # bin center times in ms
bin_cen_space: blob # bin center of space in deg
is_stim_space: blob # boolean saying which elements of bin_cen_space were actually stimulated
n: smallint unsigned # number of sub-trials or trials


strf_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef StRf < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('fle.StRf')
		popRel = fle.BarGrayLevels*fle.SpikeSets*fle.StRfParams  % !!! update the populate relation
	end

	methods
		function self = StRf(varargin)
			self.restrict(varargin{:})
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
		 tup = key;
            % Compute bin_width
            T = fetch1(vstim.RefreshPeriod(key),'refresh_period_msec');
            [bar_width, nFlash] = fetch1(fle.StimConstants(key),'bar_size_x','num_flash_locs_barmap');
            f = bar_width/key.bar_cen_spacing_pix;
            % Make sure that the bar width is a integer multiple of bar_cen_spacing_pix
            assert((f-round(f))==0, 'bar width should be an integer multiple of bar_cen_spacing_pix')
            
            bw = tup.bin_width;
                      
            % Get bin edges: trajectory times should end up being bin centers
            n_pre_stim_bins = round(key.pre_stim_time/bw);
            n_post_stim_bins = round(key.post_stim_time/bw);
            
            nStimBins = 1; % Flashed for one frame
            bin_cen = (-n_pre_stim_bins:(nStimBins+n_post_stim_bins))*bw;
            bin_edges = [bin_cen bin_cen(end)+bw]-bw/2 ;
            nTimeBins = length(bin_cen);
            
            % Go to each flash location and get mean firing rate
            % We will only consider 'single' conditions: ie. no combined flash condition
            qs = sprintf('flash_in_rf = 1 and mov_shown = 0 and bar_color_r = %u',key.bar_gray_level);
            flash_cond = sort(fetchn(fle.StimCenProxCond(key,qs),'cond_idx'));
            nFlashCond = length(flash_cond);
            assert(nFlashCond==nFlash,'Number of flashes wrong!')
            
            mean_fr = zeros(nTimeBins,nFlash);
            trialSpikes = cell(1,nFlash);
            tmp = struct;
            
            for iFlash = 1:nFlash
                cs = sprintf('cond_idx = %u',flash_cond(iFlash));
                skeys = fetch(fle.SubTrials(key,cs)-fle.SubTrialsIgnore);
                [stim_on, stim_off, trialSpikes{iFlash}] = fetchn(fle.SubTrials(skeys) * fle.SubTrialSpikes(key,skeys),'substim_on','substim_off','spike_times');
                assert(round(median((stim_off-stim_on))/T)==1,'Flash was not shown for 1 frame')
                [tmp.bar_cen_deg(iFlash),tmp.bar_cen_pix(iFlash)] = fetch1(fle.RelFlashCenX(key,cs),'rel_to_mon_cen_deg','rel_to_mon_cen_pix');
            end
            n = min(cellfun(@length, trialSpikes));
            for iFlash = 1:nFlash
                % Get binned spikes
                tspk = trialSpikes{iFlash}(1:n);
                tspk = cat(1,tspk{:});
                bc = histc(tspk,bin_edges);
                bc = bc(1:end-1);
                mean_fr(:,iFlash)  = bc*(1000/bw)/n;
            end
            
            tup.bin_cen_times = bin_cen';
            tup.n = n;
            
            % Now interpolate so that we can match flash locations to moving bar locations
            % Locations:
            bci_pix = tmp.bar_cen_pix(1):key.bar_cen_spacing_pix:tmp.bar_cen_pix(end);
            assert(all(ismember(tmp.bar_cen_pix, round(bci_pix))),'Interpolation missed real flash locations')
            tup.bin_cen_space = interp1(tmp.bar_cen_pix, tmp.bar_cen_deg, bci_pix)';
            tup.is_stim_space = ismember(sort(round(bci_pix)),sort(tmp.bar_cen_pix))';
            
            % Interpolate mean firing rate at intermediate locations -  Go through each
            % time bin
            tup.space_time_map = (interp1(tmp.bar_cen_deg, mean_fr', tup.bin_cen_space))';
            
            
            self.insert(tup)
		end
	end
end
