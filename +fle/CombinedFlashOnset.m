%{
fle.CombinedFlashOnset (computed) # Flash onset time when moving was also presented

-> fle.SubTrials
---
t                       : double                        # flash onset time in msec
%}

classdef CombinedFlashOnset < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.CombinedFlashOnset')
        popRel = (fle.SubTrials & fle.StimConstants('combined = 1')) & ...
            fle.StimCond('is_moving = 1 and is_flash = 1')  % combined condition only
    end
    methods
        function self = CombinedFlashOnset(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)
        
        function makeTuples(self, key)

            % For LCD monitor based sessions, we showed flashes and moving bars at zero
            % flash offset for all flash locations. For CRT monitors, we showed multiple
            % flash offsets when moving bar was at stimulus center.
            mon_type = fetch1(fle.StimConstants(key),'monitor_type');
            traj_t = fetch1(fle.TrajTimes(key),'t');
            s = fetch(fle.SubTrials(key),'bar_locations','flash_locations');
            
            switch mon_type
                case 'LCD'
                    key.t = traj_t(s.bar_locations{:} == s.flash_locations{:});
                case 'CRT'
                    key.t = traj_t(s.bar_locations{:} == 0);
                otherwise
                    error('unknown monitor type')
            end
            
            self.insert(key)
        end
    end
end
