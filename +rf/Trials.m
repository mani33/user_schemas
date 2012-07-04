%{
rf.Trials (computed) # my newest table
-> rf.TrialGroup
-> stimulation.StimTrials
-----
stim_on       : bigint unsigned       # showStimulus time
stim_off      : bigint unsigned       # endStimulus time
swap_times    : blob                  # swap times
dot_colors    : blob                  # dot color that was used in each stimulus frame
dot_locations : blob                  # location where dot was shown
%}


classdef Trials < dj.Relvar

	properties(Constant)
		table = dj.Table('rf.Trials')
	end

	methods
		function self = Trials(varargin)
			self.restrict(varargin)
		end

		function makeTuples(self, key)
		fprintf('Computing tuples')
            tic
            %!!! compute missing fields for key here
            td = fetch(stimulation.StimTrials(key),'trial_params','valid_trial');
            vInd = find([td.valid_trial]);
            nVtrials = numel(vInd);
           
            
            
            for ivTrial = 1:nVtrials
                currTrial = vInd(ivTrial);
                key.trial_num = td(currTrial).trial_num;

                
                key.stim_on = fetch1(stimulation.StimTrialEvents(key,...
                    'event_type = ''showStimulus'''),'event_time');
                key.stim_off = fetch1(stimulation.StimTrialEvents(key,...
                    'event_type = ''endStimulus'''),'event_time');
               
                key.swap_times = td(currTrial).trial_params.swapTimes;
                key.dot_colors = td(currTrial).trial_params.dotColors;
                key.dot_locations = td(currTrial).trial_params.dotLocations;
                self.insert(key)
            end
            
            fprintf(' (%0.0f s) -->',toc);
            tic
		end
	end
end
