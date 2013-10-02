%{
flevbl.TrajTimes (computed) # table to get motion trajectory frame times
-> flevbl.SubTrials

-----
t : blob # times of motion frames
%}

classdef TrajTimes < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('flevbl.TrajTimes')
		popRel = flevbl.SubTrials & flevbl.StimCond('is_moving = 1')  % !!! update the populate relation
	end
    methods
        function self = TrajTimes(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)

		function makeTuples(self, key)
            tuple = key;
            [trial_num, bar_locs, on, off] = fetchn(flevbl.SubTrials(key)-flevbl.SubTrialsIgnore,'trial_num','bar_locations','substim_on','substim_off');
            cs = sprintf('trial_num = %u',trial_num);
            % Get swap times and pick the subset between substim on and substim off times
            tp = fetch1(stimulation.StimTrials(key,cs),'trial_params');
            st = tp.swapTimes;
            rst = round(st);
            tuple.t = st(rst >= on & rst < off);
            nObs = length(tuple.t);
            nExp = length(cell2mat(bar_locs{:}));
            assert(nObs==nExp,sprintf('possibly missing some frame times: expected %u , found %u',nExp,nObs))
            self.insert(tuple)
		end
	end
end
