%{
fle.SubTrialRelStimSwapTimes (computed) # my newest table
-> fle.SubTrials

-----
rel_swap_times: mediumblob # swap times in sec relative to subStimulus onset
%}

classdef SubTrialRelStimSwapTimes < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.SubTrialRelStimSwapTimes')
        popRel = fle.SubTrials  % !!! update the populate relation
    end
    
    methods
        function self = SubTrialRelStimSwapTimes(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            % Get swap times for the trial in which this subtrial was part of
            d = fetch(fle.SubTrials(key),'*');
            tp = fetch1(stimulation.StimTrials(d),'trial_params');
            st = tp.swapTimes;
            % Extract swap times corresponding to stimulus period only
            sel_st = st(round(st) >= d.substim_on & round(st) <= d.substim_off);
            key.rel_swap_times = sel_st - sel_st(1);
            assert(length(sel_st)>=2,sprintf('Number of time stampes = %u\n',length(sel_st)))
            self.insert(key)
        end
    end
end
