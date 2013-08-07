%{
flevbl.Traj (computed) # trajectory info - space and time
-> flevbl.TrialGroup
flash_in_rf : boolean # was flash presented at receptive field
mov_in_rf : boolean # was moving bar presented at receptive field
flash_shown : boolean # was flash shown
mov_shown : boolean # was moving bar shown
dx : tinyint unsigned # pixels per frame
direction: boolean # direction of motion 0 - LR, 1 - RL
bar_color_r: tinyint unsigned # bar color red channel

-----
sx : blob # locations_x of motion frames
sy : blob # locations_y of motion frames
t : blob # relative times of motion frames
traj_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef Traj < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.Traj')
        popRel = flevbl.TrialGroup & flevbl.StimConstants('flash_init = 0 and flash_stop = 0 and monitor_type = "CRT"') & vstim.PixPerDeg  % !!! update the populate relation
    end
    
    methods
        function self = Traj(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            dxs = fetchn(flevbl.DxVals(key),'dx');
            nDx = length(dxs);
            comb = fetch1(flevbl.StimConstants(key),'combined');
            grays = fetchn(flevbl.BarGrayLevels(key),'bar_gray_level');
            nGray = length(grays);
            ppd = fetch1(vstim.PixPerDeg(key),'pix_per_deg');
            scon = fetch(flevbl.StimConstants(key),'*');
            if comb
                % flash_in_rf   flash_shown   mov_in_rf  mov_shown
                arr = [1 1 0 1; % combined
                       0 1 1 1; % combined
                       0 0 1 1]; % single
            else
                arr = [0 0 1 1];
            end
            
            nArr = size(arr,1);
            
            for iDir = 1:2
                for iDx = 1:nDx
                    dx = dxs(iDx);
                    for iGray = 1:nGray
                        gray = grays(iGray);
                        for iArr = 1:nArr
                            
                            tuple = key;
                            
                            crr = arr(iArr,:);
                            arr_str = sprintf('flash_in_rf = %u and flash_shown = %u and mov_in_rf = %u and mov_shown = %u',crr(1),crr(2),crr(3),crr(4));
                            cond_str = sprintf('direction = %u and dx = %u and bar_color_r = %u and %s',...
                                iDir-1, dxs(iDx), gray, arr_str);
                            if crr(2) && crr(4) % just pick one flash offset
                                cond_idx = fetchn(flevbl.StimCenProxCond(key, cond_str),'cond_idx');
                                cond_idx = cond_idx(1);
                            else
                                cond_idx = fetch1(flevbl.StimCenProxCond(key, cond_str),'cond_idx');
                            end
                            cs = sprintf('cond_idx = %u',cond_idx);
                            [trial_num, bar_centers, on, off] = fetchn(flevbl.SubTrials(key,cs)-flevbl.SubTrialsIgnore,'trial_num','bar_centers','substim_on','substim_off');
                            
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
                                                        
                            assert(all(range(t,2) < 0.3),'time stamps range exceeds 0.3 ms')
                            tuple.t = median(t,2);
                            tuple.sx = (bcx(:,1) - scon.monitor_center_x)/ppd;
                            tuple.sy = (bcy(:,1) - scon.monitor_center_y)/ppd;
                            
                            tuple.dx = dx;
                            tuple.direction = iDir-1;
                            tuple.bar_color_r = gray;
                            tuple.flash_in_rf = crr(1);
                            tuple.flash_shown = crr(2);
                            tuple.mov_in_rf = crr(3);
                            tuple.mov_shown = crr(4);
                            self.insert(tuple)
                        end
                    end
                end
            end
        end
    end
end
