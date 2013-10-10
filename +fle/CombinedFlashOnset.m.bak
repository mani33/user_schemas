%{
flevbl.CombinedFlashOnset (computed) # Flash onset time when moving was also presented

-> flevbl.SubTrials
---
onset                       : double                        # flash onset time in msec
%}

classdef CombinedFlashOnset < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.CombinedFlashOnset')
        popRel = (flevbl.SubTrials & flevbl.StimConstants('combined = 1')) & ...
            flevbl.StimCond('is_moving = 1 and is_flash = 1')  % combined condition only
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
            mon_type = fetch1(flevbl.StimConstants(key),'monitor_type');
            traj_t = fetch1(flevbl.TrajTimes(key),'t');
            s = fetch(flevbl.SubTrials(key),'bar_locations','flash_locations');
            
            switch mon_type
                case 'LCD'
                    key.onset = traj_t(s.bar_locations{:} == s.flash_locations{:});
                case 'CRT'
                    key.onset = traj_t(s.bar_locations{:} == 0);
                otherwise
                    error('unknown monitor type')
            end
            
            self.insert(key)
        end
    end
end
