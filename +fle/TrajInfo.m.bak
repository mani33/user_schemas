%{
flevbl.TrajInfo (computed) # my newest table
-> flevbl.StimCond
-----
sx : blob # locations_x of motion frames
sy : blob # locations_y of motion frames
t : blob # relative times of motion frames
trajinfo_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef TrajInfo < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.TrajInfo')
        popRel = flevbl.StimCond('is_moving = 1') & vstim.PixPerDeg  % !!! update the populate relation
    end
    
    methods
        function self = TrajInfo(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            % First get all condition indices for moving stimuli
            [trial_num, bar_centers, on, off, subtrial_num] = fetchn(flevbl.SubTrials(key)-flevbl.SubTrialsIgnore,'trial_num','bar_centers','substim_on','substim_off','subtrial_num');
            ppd = fetch1(vstim.PixPerDeg(key),'pix_per_deg');
            scon = fetch(flevbl.StimConstants(key),'*');
            
            nTrials = length(trial_num);
            t = cell(1,nTrials);
            bcx = t;
            bcy = t;
            for iTrial = 1:nTrials
                tcs = sprintf('trial_num = %u',trial_num(iTrial));
                % Get swap times and pick the subset between substim on and substim off times
                tp = fetch1(stimulation.StimTrials(key,tcs),'trial_params');
                st = tp.swapTimes;
                rst = round(st);
                tt = st(rst >= on(iTrial) & rst < off(iTrial));
                t{iTrial} = tt(:)-tt(1);
                nObs = length(t{iTrial});
                bc = cell2mat(bar_centers{iTrial})';
                bcx{iTrial} = bc(:,1);
                bcy{iTrial} = bc(:,2);
                
                nExp = size(bc,1);
                assert(nObs==nExp,sprintf('possibly missing some frame times: expected %u , found %u',nExp,nObs))
            end
            
            
            bcx = [bcx{:}];
            bcy = [bcy{:}];
            t = [t{:}];
            assert(all(range(bcx,2)==0),'bar center x has got problem')
            assert(all(range(bcy,2)==0),'bar center y has got problem')
            
            
            % Make sure all trials had all frames presented and the frames were
            % presented within 1 ms jitter
            
            % Check for missing frames
            mf = diff(t,1,1);
            mfr = range(mf,1);
            missed_frame_trials = mfr > 5;
            bad = find(missed_frame_trials);
            nBad = length(bad);
            % Remove bad trials and check for across trials jitter
            tg = t(:,~missed_frame_trials);
            atj = range(tg,2);
            assert(all(atj) < 1, 'Timing jitter across trials more than 1 ms')
            
            if nBad > 0
                fprintf('%u trials had missing frames. They are inserted into SubtrialsIgnore table\n\n',nBad)
                rea = 'missed frames';
                for iBad = 1:nBad
                    sub_num = subtrial_num(bad(iBad));
                    tnum = trial_num(bad(iBad));
                    skey = fetch(flevbl.SubTrials(key,sprintf('subtrial_num = %u and trial_num = %u',sub_num,tnum)));
                    skey.reason = rea;
                    assert(length(key)==1,'more than one key to insert?')
                    insert(flevbl.SubTrialsIgnore,skey)
                end
            end
            key.t = median(tg,2);
            key.sx = (bcx(:,1) - scon.monitor_center_x)/ppd;
            key.sy = (bcy(:,1) - scon.monitor_center_y)/ppd;
            
            self.insert(key)
        end
    end
end

