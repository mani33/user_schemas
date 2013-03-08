%{
flevbl.CombinedFlashOnset (computed) # Flash onset time when moving was also presented
-> flevbl.SubTrials

-----
t : double # flash onset time in msec
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
		%!!! compute missing fields for key here
        traj_t = fetch1(flevbl.TrajTimes(key),'t');
       s = fetch(flevbl.SubTrials(key),'bar_locations','flash_locations');
        key.t = traj_t(s.bar_locations{:} == s.flash_locations{:});
        self.insert(key)
        end
    end
end
