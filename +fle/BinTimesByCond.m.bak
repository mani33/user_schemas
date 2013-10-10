%{
flevbl.BinTimesByCond (computed) # for single conditions, bin times for flash and moving

-> flevbl.Bw
-> flevbl.SpikeWinParams
-> flevbl.StimCond
---
t                           : blob                          # bin center times in ms relative to stimulus onset
bw_t                        : double                        # actual bin width used
%}

classdef BinTimesByCond < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.BinTimesByCond')
        popRel = (flevbl.SpikeWinParams * flevbl.StimCond('not (is_flash = 1 and is_moving = 1)') * ...
            flevbl.Bw) & flevbl.TrajTimes & vstim.RefreshPeriod & vstim.PixPerDeg  % !!! update the populate relation
    end
    
    methods
        function self = BinTimesByCond(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            T = fetch1(vstim.RefreshPeriod(key),'refresh_period_msec');
            bw = T * key.t_frac;
            key.bw_t = bw;
            % Check to make sure that all trials within the given condition had nearly the
            % same stimulus duration
            skeys = fetch(flevbl.SubTrials(key)-flevbl.SubTrialsIgnore);
            d = fetch(flevbl.SubTrials(skeys),'substim_on','substim_off');
            
            % Remove subtrials which do not resemble the majority of the subtrials
            off = [d.substim_off];
            on = [d.substim_on];
            r = off - on;
            m = median(r);
            bad = (r > m+T/2 | r < m-T/2);
            nBad = length(find(bad));
            off = off(~bad);
            on = on(~bad);
            
            if nBad > 0
                bk = fetch(flevbl.SubTrials(skeys(bad)));
                igr = 'Time stamps missing or bad';
                if nBad > 10
                    disp('Too many bad trials - see what is going on')
                    keyboard
                end
                fprintf('Found %u trials with weird time stamps. Inserting them into SubTrialsIgnore ...\n',nBad);
                for i = 1:nBad
                    tuple = bk(i);
                    tuple.reason = igr;
                    insert(flevbl.SubTrialsIgnore,tuple)
                end
            end
            assert(all(range(off-on) < 2.5), 'Subtrials differ in stimulus duration')
            st = median(off-on);
            
            % Compute bin centers
            % For flash, we will just use bin width based on refresh period
            if fetch1(flevbl.StimCond(key),'is_flash')
                postBins = ceil((st + key.post_stim_time)/bw);
                preBins = ceil(key.pre_stim_time/bw);
                key.t = (-preBins:postBins)*bw;
            else
                % Note that for moving stimulus, one extra frame was drawn (fixation spot)
                % before taking the endSubStimulus time stamp. Hence, we need to subtract
                % one frame time from the stimulus duration.
                %                 st = st -T;
                % For moving, we want to make sure that every moving bar location has a
                % corresponding bin center time point
                tt = fetchn(flevbl.TrajTimes(skeys),'t');
                % Check if all trials had same relative trajectory time points
                tt = [tt{:}];
                tt = bsxfun(@minus, tt, tt(1,:));
                assert(all(range(tt,2) < 1.1), 'Trials differ in traj times')
                % Now make sure that the traj times are part of bin centers to start with
                t = median(tt,2);
                % Interpolate
                g = 1:length(t);
                % Allow only 0.25 and 0.5 for t_frac
                assert(any(ismember([0.25 0.5],key.t_frac)),'use only 0.25 or 0.5 as t_frac in flevbl.Bw table')
                gi = 1:key.t_frac:length(t);
                % Trajectory part
                mt = interp1(g,t,gi,'linear');
                % Pre and post stimulus part
                dt = median(diff(mt));
                nPre = ceil(key.pre_stim_time/dt);
                nPost = ceil(key.post_stim_time/dt);
                pre = (-nPre:-1)*dt;
                post = (1:nPost)*dt;
                key.t = [pre mt mt(end)+post];
            end
            key.t = key.t(:);
            self.insert(key)
        end
    end
end
