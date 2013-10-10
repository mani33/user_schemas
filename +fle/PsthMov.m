%{
fle.PsthMov (computed) # my newest table
-> fle.SpikeSets
-> fle.PsthParams
-> fle.StimCond
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
        table = dj.Table('fle.PsthMov')
        popRel = (fle.SpikeSets * fle.PsthParams * fle.StimCond('is_moving = 1')) & vstim.RefreshPeriod % !!! update the populate relation
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
            
            bar_width = fetch1(fle.StimConstants(key),'bar_size_x');
            f = bar_width/key.bar_cen_spacing_pix;
            % Make sure that the bar width is a integer multiple of bar_cen_spacing_pix
            assert((f-round(f))==0, 'bar width should be an integer multiple of bar_cen_spacing_pix')
            
            ppd = fetch1(vstim.PixPerDeg(key),'pix_per_deg');
            
            subRv = fle.SubTrials(key)-fle.SubTrialsIgnore;
            skeys = fetch(subRv);
            [stim_on,traj_abs_times,trialSpikes,bar_centers] = fetchn(fle.SubTrials(skeys)*fle.TrajTimes(skeys)*fle.SubTrialSpikes(key,skeys),'substim_on','t','spike_times','bar_centers');
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
                    insert(fle.SubTrialsIgnore,bad_tup);
                end
                trialSpikes = trialSpikes(good);
                traj_rel_times = traj_rel_times(good);
                bar_centers = bar_centers(good);
            end
            traj_rel_times = [traj_rel_times{:}];
            
            % Check similarity of time stamps across trials
            rt = range(traj_rel_times,2);
            assert(max(rt) < 2, 'time stamps for location differ by more than 1.5 ms across trials')
            
            traj_t = median(traj_rel_times,2);
            traj_t = traj_t - traj_t(1);
            nTrials = length(trialSpikes);
            tup.n = nTrials;
           
            bw = mean(diff(traj_t))/f;
            n_pre_stim_bins = round(key.pre_stim_time/bw);
            n_post_stim_bins = round(key.post_stim_time/bw);
            tup.bin_width = bw;
            
            %------------------------------------------------------------------
            
            % 1. Get trajectory bar centers relative to monitor center in pixels
            traj_bar_cen_pix = bar_centers{1}{:};
            traj_s = traj_bar_cen_pix(1,:) - fetch1(fle.StimConstants(key),'monitor_center_x');
            
            % Get bin edges: trajectory times should end up being bin centers
            nTrajLocs = round((traj_t(end)-traj_t(1))/bw)+1;
            % Make finer space and time bins
            traj_ti = linspace(traj_t(1),traj_t(end),nTrajLocs);
            % For motion reversals, we need handle things a bit differently
            
            if logical(fetch1(fle.StimCond(key),'is_reverse'))
                assert(mod(length(traj_s),2)==1,' number of traj loc should be odd')
                rp = (length(traj_s)+1)/2;
                assert(mod(nTrajLocs,2)==1,'num of interpolated traj loc should be odd')
                % Interpolate the two halfs of the trajectory of reversal separately
                ni = (nTrajLocs+1)/2;
                s1 = linspace(traj_s(1), traj_s(rp), ni);
                s2 = linspace(traj_s(rp), traj_s(end), ni);
                traj_si = [s1 s2(2:end)];
            else
                traj_si = linspace(traj_s(1),traj_s(end),nTrajLocs);
            end
            bs = diff(traj_si(1:2));
            
            % Extend the 'traj' now to include pre_stim_time and post_stim_time
            traj_ti_ext = [((-n_pre_stim_bins:-1)*bw)+traj_ti(1)    traj_ti   traj_ti(end)+(1:n_post_stim_bins)*bw];
            % Catenate according to the direction of motion
            traj_si_ext = [((-n_pre_stim_bins:-1)*bs)+traj_si(1)    traj_si   traj_si(end)+(1:n_post_stim_bins)*bs];
            
            bin_cen = traj_ti_ext;
            bin_edges = [bin_cen bin_cen(end)+bw]-bw/2 ;
            
            tup.bin_cen_times = bin_cen';
            tup.is_traj = [false(1,n_pre_stim_bins) true(1,nTrajLocs) false(1,n_post_stim_bins)]';
            tup.bin_cen_space = traj_si_ext'/ppd;
            
            % Find which space points were interploated ones 
            traj_locs = false(1,nTrajLocs);
            traj_locs(1:f:end) = true;            
            tup.is_stim_space = [false(1,n_pre_stim_bins) traj_locs false(1,n_post_stim_bins)]';
            
            assert(all(ismember(traj_s, traj_si)),'Interpolation missed some stimulated spatial locations')
            % Get binned spikes
            bspk = cat(1,trialSpikes{:});
            bc = histc(bspk,bin_edges);
            bc = bc(1:end-1);
            tup.mean_fr  = bc(:)*(1000/bw)/nTrials;
            
            self.insert(tup)
        end
    end
end
