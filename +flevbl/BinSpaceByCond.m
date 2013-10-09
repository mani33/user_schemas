%{
flevbl.BinSpaceByCond (computed) # my newest table
-> flevbl.BinTimesByCond

-----
sx : blob # space in degrees corresponding to the time points
is_traj = Null : blob # which space positions were part of trajectory
is_stim = Null : blob # at which positions the bar centers were presented
bw_s = Null : double                        # actual bin width used
binspacebycond_ts = CURRENT_TIMESTAMP: timestamp  # do not edit

%}

classdef BinSpaceByCond < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.BinSpaceByCond')
        popRel = flevbl.BinTimesByCond & (flevbl.TrajInfo | flevbl.RelFlashCenX)% !!! update the populate relation
    end
    
    methods
        function self = BinSpaceByCond(varargin)
            self.restrict(varargin{:})
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            % Note that 'combined' sessions are excluded already by BinTimesByCond table. So
            % we are dealing only with 'single' conditions.
            ti = fetch1(flevbl.BinTimesByCond(key),'t');
            [flash,reverse] = fetchn(flevbl.StimCond(key),'is_flash','is_reverse');
            if flash
                loc = fetch1(flevbl.RelFlashCenX(key),'rel_to_mon_cen_deg');
                T = fetch1(vstim.RefreshPeriod(key),'refresh_period_msec');
                
                % We assume that the flash was presented for one video frame
                
                key.sx = nan(length(ti),1);
                key.sx(ti >=0 & ti < T) = loc;
                f = ~isnan(key.sx);
                assert(length(find(f))==round(1/key.t_frac),'more frames have flash')
                key.bw_s = 0;
                key.is_traj = f(:);
                key.is_stim = f(:);
            else
                d = fetch(flevbl.TrajInfo(key),'sx','t');
                is_trj = false(length(ti),1);
                is_trj(ti >= d.t(1) & ti <= d.t(end)) = true;
                ti_trj = ti(is_trj);
                key.is_traj = is_trj;
                key.is_stim = ismember(ti,d.t);
                if reverse
                    % Since the trajectory reverses, we cannot interpolate the whole
                    % trajectory; we have to split at the reversal point and interpolate
                    % the two pieces separately to find space points corresponding to the
                    % time points.
                    assert(mod(length(d.sx),2)==1,' number of traj loc should be odd')
                    rp = (length(d.sx)+1)/2;
                    rpi = find(ti_trj == d.t(rp));
                    part1i = interp1(d.t(1:rp), d.sx(1:rp), ti_trj(1:rpi), 'linear');
                    part2i = interp1(d.t(rp:end), d.sx(rp:end), ti_trj(rpi:end), 'linear');
                    si_trj = cat(1,part1i, part2i(2:end));
                    
                    % Next, extend the space points to outside the trajectory
                    ds_pre = diff(si_trj(1:2));
                    ds_post = diff(si_trj(end-1:end));
                    nPre = length(find(ti < ti_trj(1)));
                    nPost = length(find(ti > ti_trj(end)));
                    pre = (-nPre:-1)'*ds_pre + si_trj(1);
                    post = (1:nPost)'*ds_post + si_trj(end);
                    
                else
                    % First interpolate to find space points within trajectory
                    si_trj = interp1(d.t,d.sx,ti_trj,'linear');
                    
                    % Next, extend the space points to outside the trajectory
                    ds = diff(si_trj(1:2));
                    nPre = length(find(ti < ti_trj(1)));
                    nPost = length(find(ti > ti_trj(end)));
                    pre = (-nPre:-1)'*ds + si_trj(1);
                    post = (1:nPost)'*ds + si_trj(end);
                end
                key.sx = cat(1,pre,si_trj,post);
                % Get bin width in space
                key.bw_s = median(abs(diff(si_trj)));
            end
            self.insert(key)
        end
    end
end
