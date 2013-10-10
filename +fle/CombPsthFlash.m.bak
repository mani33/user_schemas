%{
flevbl.CombPsthFlash (computed) # Space time receptive field in the presense of motion
-> flevbl.BarGrayLevels
-> flevbl.CombPsthParams
-> flevbl.SpikeSets
-> flevbl.DxVals
-----
bin_width: double # bin_width in msec
space_time_map: blob # mean firing rate map
bin_cen_times: blob # bin center times in ms
bin_cen_space: blob # bin center of space in deg
is_stim_space: blob # boolean saying which elements of bin_cen_space were actually stimulated
n: smallint unsigned # number of sub-trials or trials


combpsthflash_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef CombPsthFlash < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.CombPsthFlash')
        popRel = flevbl.BarGrayLevels * flevbl.DxVals * flevbl.CombPsthParams * flevbl.SpikeSets  % !!! update the populate relation
    end
    
    methods
        function self = CombPsthFlash(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            
            tup = key;
            % Compute bin_width
            T = fetch1(vstim.RefreshPeriod(key),'refresh_period_msec');
            skey = fetch(flevbl.TrialGroup(key));
            [bar_width, nFlash] = fetch1(flevbl.StimConstants(skey),'bar_size_x','num_flash_locs_barmap');
            f = bar_width/key.bar_cen_spacing_pix;
            % Make sure that the bar width is a integer multiple of bar_cen_spacing_pix
            assert((f-round(f))==0, 'bar width should be an integer multiple of bar_cen_spacing_pix')
            
            bw = T/f;
            tup.bin_width = bw;
            
            % Get bin edges
            n_pre_stim_bins = round(key.peri_flash_time/bw);
            n_post_stim_bins = round(key.peri_flash_time/bw);
            
            nStimBins = 1; % Flashed for one frame
            bin_cen = (-n_pre_stim_bins:(nStimBins+n_post_stim_bins))*bw;
            bin_edges = [bin_cen bin_cen(end)+bw]-bw/2 ;
            nTimeBins = length(bin_cen);
            
            
            
            % For LCD monitor based sessions, we showed flashes and moving bars at zero
            % flash offset for all flash locations. For CRT monitors, we showed multiple
            % flash offsets when moving bar was at stimulus center.
            mon_type = fetch1(flevbl.StimConstants(skey),'monitor_type');
            
            switch mon_type
                case 'CRT'
                    
                    % Go to each flash location and get mean firing rate
                    % We will only consider 'combined' conditions: ie. combined flash and motion condition                    
                  
                            qs = sprintf('flash_shown = 1 and mov_shown = 1 and bar_color_r = %u and flash_in_rf = 1 and mov_in_rf = 0',...
                                key.bar_gray_level);
                            
                            flash_cond = sort(fetchn(flevbl.StimCenProxCond(key,qs),'cond_idx'));
                            nFlashCond = length(flash_cond);
                            assert(nFlashCond==nFlash,'Number of flashes wrong!')
                            
                            mean_fr = zeros(nTimeBins,nFlash);
                            trialSpikes = cell(1,nFlash);
                            tmp = struct;
                            
                            for iFlash = 1:nFlash
                                cs = sprintf('cond_idx = %u',flash_cond(iFlash));
                                skeys = fetch(flevbl.SubTrials(key,cs)-flevbl.SubTrialsIgnore);
                                [flash_on, stim_on, stim_off,trialSpikes{iFlash}] = fetchn(flevbl.CombinedFlashOnset(skeys) * flevbl.SubTrials(skeys)...
                                    * flevbl.SubTrialSpikes(key,skeys),'onset','substim_on','substim_off','spike_times');
                                tmp.rel_flash_on{iFlash} = flash_on-stim_on;
                                tmp.stim_time(iFlash) = median(stim_off-stim_on);
                                [tmp.bar_cen_deg(iFlash),tmp.bar_cen_pix(iFlash)] = fetch1(flevbl.RelFlashCenX(key,cs),'rel_to_mon_cen_deg','rel_to_mon_cen_pix');
                            end
                            flash_onset = cat(1,tmp.rel_flash_on{:});
                            assert(range(flash_onset) < 2, 'relative flash on times differ by more than 2 ms across subtrials')
                            flash_onset = median(flash_onset);
                            
                            
                            % Make sure that there is enough post_stim_time to cover
                            % post_flash_time after shifting the zero time point to flash
                            % onset time
                            flash_duration = unique(fetchn(vstim.RefreshPeriod(key),'refresh_period_msec'));
                            assert((flash_onset + flash_duration+ key.peri_flash_time) < (mean(tmp.stim_time)/2+key.post_stim_time), 'post_stim_time not sufficient for the given post_flash_time')
                            n = min(cellfun(@length, trialSpikes));
                            for iFlash = 1:nFlash
                                % Get binned spikes
                                tspk = trialSpikes{iFlash}(1:n);
                                tspk = cat(1,tspk{:});
                                % Center the spike times to flash onset time
                                tspk = tspk-flash_onset;
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
                    
                case 'LCD'
                    error('Code not implemented yet')
                otherwise
                    error('Unknown monitor type')
            end
        end
    end
end

