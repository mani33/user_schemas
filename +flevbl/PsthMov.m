%{
flevbl.PsthMov (computed) # my newest table
-> flevbl.SpikeSets
-> flevbl.PsthParams
-> flevbl.StimCond
-----
bin_width: double # bin_width in msec
bin_cen_times: blob # time(ms) relative to moving bar onset
bin_cen_space: blob # space in degrees relative to monitor center
is_traj: blob # boolean saying which element of bin_cen_* is part of trajectory
is_stim_space: blob # boolean saying at which elements of traj_s bars were actually presented
mean_fr: blob # mean firing rate (Hz) across trials
n: smallint unsigned # number of sub-trials or trials

psthmov_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef PsthMov < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.PsthMov')
        popRel = (flevbl.SpikeSets * flevbl.PsthParams * flevbl.StimCond('is_moving = 1')) & vstim.RefreshPeriod % !!! update the populate relation
    end
    
    methods
        function self = PsthMov(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            tup = key;
            % Compute bin_width
            T = fetch1(vstim.RefreshPeriod(key),'refresh_period_msec');
            bar_width = fetch1(flevbl.StimConstants(key),'bar_size_x');
            f = bar_width/key.bar_cen_spacing_pix;
            % Make sure that the bar width is a integer multiple of bar_cen_spacing_pix
            assert((f-round(f))==0, 'bar width should be an integer multiple of bar_cen_spacing_pix')
            
            bw = T/f;
            tup.bin_width = bw;
            
            n_pre_stim_bins = round(key.pre_stim_time/bw);
            n_post_stim_bins = round(key.post_stim_time/bw);
            
            ppd = fetch1(vstim.PixPerDeg(key),'pix_per_deg');
            
            subRv = flevbl.SubTrials(key)-flevbl.SubTrialsIgnore;
            skeys = fetch(subRv);
            [stim_on,traj_abs_times,trialSpikes,bar_centers] = fetchn(flevbl.SubTrials(skeys)*flevbl.TrajTimes(skeys)*flevbl.SubTrialSpikes(key,skeys),'substim_on','t','spike_times','bar_centers');
            traj_rel_times = cellfun(@(x,on) x - on, traj_abs_times,num2cell(stim_on),'uni',false);
            
            % The onset time (the first element of traj_rel_times) may not be exactly
            % zero; but it should be within a msec.
            
            trj_t = [traj_rel_times{:}];
            rr = range(diff(trj_t,1,1),1);
            good = rr < 1;
            if ~all(good)
                badKeys = skeys(~good);
                brr = rr(~good);
                fprintf('Found %u/%u trials with time stamps missing!\n',length(badKeys),length(trialSpikes))
                for ib = 1:length(badKeys)
                    bad_tup = badKeys(ib);
                    bad_tup.reason = 'One or more swap times missed';
                    fprintf('Inserting bad trials (range of flipTime diff: %0.2f ms) into subtrialsIgnore table\n',brr(ib))
                    insert(flevbl.SubTrialsIgnore,bad_tup);
                end
                trialSpikes = trialSpikes(good);
                traj_rel_times = traj_rel_times(good);
                bar_centers = bar_centers(good);
            end
            traj_rel_times = [traj_rel_times{:}];
            traj_rel_times = median(traj_rel_times,2);
            nTrials = length(trialSpikes);
            tup.n = nTrials;
           
            %------------------------------------------------------------------
            
            % 1. Get trajectory bar centers relative to monitor center in pixels
            traj_bar_cen_pix = bar_centers{1}{:};
            
            traj_bar_cen_pix_x = traj_bar_cen_pix(1,:) - fetch1(flevbl.StimConstants(key),'monitor_center_x');
            traj_s =  traj_bar_cen_pix_x/ppd;
            traj_t = traj_rel_times-traj_rel_times(1);
            
            % Get bin edges: trajectory times should end up being bin centers
            nTrajBins = round((traj_rel_times(end)-traj_rel_times(1))/bw);
            bin_cen = (-n_pre_stim_bins:(nTrajBins+n_post_stim_bins))*bw;
            bin_edges = [bin_cen bin_cen(end)+bw]-bw/2 ;
            
            tup.bin_cen_times = bin_cen';
            tup.is_traj = [false(1,n_pre_stim_bins) true(1,nTrajBins+1) false(1,n_post_stim_bins)]';
            tup.bin_cen_space = interp1(traj_t,traj_s,bin_cen)';
            
            % Find which space points were interploated ones 
            nTrajLocs = nTrajBins + 1;
            traj_locs = false(1,nTrajLocs);
            traj_locs(1:f:end) = true;            
            tup.is_stim_space = [false(1,n_pre_stim_bins) traj_locs false(1,n_post_stim_bins)]';
            
            % Get binned spikes
            bspk = cat(1,trialSpikes{:});
            bc = histc(bspk,bin_edges);
            bc = bc(1:end-1);
            tup.mean_fr  = bc*(1000/bw)/nTrials;
            
            self.insert(tup)
        end
    end
end
