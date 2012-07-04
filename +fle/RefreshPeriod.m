%{
fle.RefreshPeriod (computed) # my newest table
-> stimulation.StimTrialGroup
-----
refresh_period_msec: double # duration (msec) of one frame
%}

classdef RefreshPeriod < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('fle.RefreshPeriod')
	end
	properties
		popRel = stimulation.StimTrialGroup - acq.StimulationIgnore; % !!! update the populate relation
	end

	methods
		function self = RefreshPeriod(varargin)
			self.restrict(varargin)
		end

		function makeTuples(self, key)
		%!!! compute missing fields for key here
            
            % Get monitor refresh period
            s = fetch(stimulation.StimTrials(key),'trial_params','valid_trial');
            s = s(logical([s.valid_trial]));
            ns = length(s);
            st = cell(1,ns);
            for i = 1:ns
                st{i} = s(i).trial_params.swapTimes';
            end
            ft = diff([st{:}]);
            ft = ft(ft > 8 & ft < 12);
            T = median(ft);
            assert(T > 9.8 && T < 10.2,'RefreshPeriod is abnormal!');
            key.refresh_period_msec = T;
			self.insert(key)
		end
	end
end
