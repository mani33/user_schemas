%{
flebm.PreFlashMeanEyePos (computed) # my newest table
-> flebm.FlashRelTime
-> flebm.PreFlashMeanEyePosParams
-> vstim.TrialEyeTraces

-----

mean_h_deg=Null: double # deg mean horizontal eye position
mean_v_deg=Null: double # deg mean vertical eye position

%}

classdef PreFlashMeanEyePos < dj.Relvar & dj.AutoPopulate

	properties(Constant)
		table = dj.Table('flebm.PreFlashMeanEyePos')
		popRel = (flebm.FlashRelTime*flebm.PreFlashMeanEyePosParams) & vstim.TrialEyeTraces  % !!! update the populate relation
	end

	methods
		function self = PreFlashMeanEyePos(varargin)
			self.restrict(varargin)
		end
	end

	methods(Access=protected)

		function makeTuples(self, key)
            %!!! compute missing fields for key here
            tuple = key;
            onset_rel_t = fetch1(flebm.FlashRelTime(key),'flash_onset_rel_time');
            start = onset_rel_t - key.pre_flash_time;
            
            dd = fetch(vstim.TrialEyeTraces(key),'*');
            rt = getRelTime(vstim.TrialEyeTraces(key));
            selInd = (rt > start) & (rt < onset_rel_t);
            
            tuple.mean_h_deg = mean(dd.trace_h_deg(selInd));
            tuple.mean_v_deg = mean(dd.trace_v_deg(selInd));
			self.insert(tuple)
		end
	end
end
