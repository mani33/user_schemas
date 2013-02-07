%{
flebh.FlashRelTime (computed) # my newest table

-> flebh.Trials
---
flash_onset_rel_time=null   : double                        # flash onset time relative to stimulus onset
%}
% MS 2013-01-10
classdef FlashRelTime < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flebh.FlashRelTime')
        popRel = flebh.Trials  % !!! update the populate relation
    end
    
    methods
        function self = FlashRelTime(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            misMatchPix = 10;
            d = fetch(flebh.Trials(key),'*');
            if d.valid_trial 
                stimOnset = fetch1(stimulation.StimTrialEvents(key,'event_type = "showStimulus"'),...
                    'event_time');
                
                % First convert the bar_locations to real monitor pixel values -
                % bar_locations are relative to the trajectory starting
                move0_start = round(d.trajectory_center_x - d.trajectory_length/2);
                move1_start = round(d.trajectory_center_x + d.trajectory_length/2);
                                
                if all(~isnan(d.flash_rect))
                    flash_cen_x = round(d.flash_rect(1) + (d.flash_rect(3)-d.flash_rect(1) + 1)/2);
                    
                    if d.move_dir==0 % motion towards right
                        move_bar_locs = round(d.bar_locations + move0_start);
                        % positive offset means flash was ahead of the moving stimulus position
                        syncLoc = flash_cen_x - d.flash_offset;
                    else % motion towards left
                        move_bar_locs =round(move1_start - d.bar_locations);
                        syncLoc = flash_cen_x + d.flash_offset;
                    end
                    
                    % Find the moving bar frame that was synchronously presented with the
                    % flash
                    [misMatch flashSyncFrame] = min(abs(move_bar_locs - syncLoc));
                    if misMatch <= misMatchPix
                        % Get flash time
                        stimOnsetInd = find(round(d.swap_times) == stimOnset);
                        flash_time = d.swap_times(stimOnsetInd + flashSyncFrame - 1);
                        key.flash_onset_rel_time = flash_time - stimOnset;
                    else
                        warning('Flash frame location didn''t have close synchronous match with moving bar location: offset = %u',misMatch)
                    end
                end
            end
            self.insert(key)
        end
    end
end
