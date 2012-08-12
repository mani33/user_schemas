%{
vstim.RefreshPeriod (computed) # my newest table
-> stimulation.StimTrialGroup
-----
refresh_period_msec: double # duration (msec) of one frame
%}

classdef RefreshPeriod < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('vstim.RefreshPeriod')
        popRel = stimulation.StimTrialGroup - acq.StimulationIgnore; % !!! update the populate relation
    end
    
    methods
        function self = RefreshPeriod(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)
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
            sc = fetch1(stimulation.StimTrialGroup(key),'stim_constants');
            
            if isfield(sc,'monitorType')
                monitorType = sc.monitorType;
            else
                monitorType = 'CRT';
            end
            
            if strcmp(monitorType,'CRT')
                ft = ft(ft > 8 & ft < 12);
                T = median(ft);
                assert(T > 9.8 && T < 10.2,...
                    sprintf('Assuming 100 Hz monitor, the computed refreshPeriod (= %0.2d) is abnormal!',T));
            elseif strcmp(monitorType,'LCD')
                ft =ft(ft > 8 & ft < 9);
                T = median(ft);
                assert(T > 8 && T < 9,...
                    sprintf('Assuming 120 Hz monitor, the computed refreshPeriod (= %0.2d) is abnormal!',T));
            end
            
            key.refresh_period_msec = T;
            self.insert(key)
        end
    end
end
