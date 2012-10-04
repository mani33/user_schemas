%{
flebm.EyeResp (computed) # my newest table
-> flebm.TrialGroup
-> vstim.FirstSaccade
-> vstim.PixPerDeg
-----
resp_dir=null: tinyint # 0 or 1 (0-left, 1-right, -1 noresponse)
resp_dir_str=null: enum('right','left','no_response') # direction moved

%}

classdef EyeResp < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flebm.EyeResp')
        popRel = vstim.FirstSaccade('subject_id = 6') & flebm.TrialGroup('subject_id = 6') & ...
            vstim.PixPerDeg('subject_id = 6');
    end
    
    methods
        function self = EyeResp(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            tuple = key;
            %!!! compute missing fields for key here
            td = fetch(flebm.Trials(key),'target_radius',...
                'left_target','right_target');
            [mx my] = fetchn(flebm.StimConstants(key),'monitor_center_x','monitor_center_y');
            tl_x = td.left_target(1) - mx;
            tl_y = td.left_target(2) - my;
            tr_x = td.right_target(1) - mx;
            tr_y = td.right_target(2) - my;
            targ_rad = td.target_radius;
            
            sac_off_time = fetch1(vstim.FirstSaccade(key),'sac_offset_rel_time');
            if ~isnan(sac_off_time)
                ed = fetch(vstim.TrialEyeTraces(key),'trace_h_deg','trace_v_deg');
                rt = getRelTime(vstim.TrialEyeTraces(key));
                sac_end_ind = find(rt > sac_off_time,1,'first');
                
                ppd = fetch1(vstim.PixPerDeg(key),'pix_per_deg');
                
                % Use pixels as common unit
                sx = ed.trace_h_deg(sac_end_ind)*ppd;
                sy = ed.trace_v_deg(sac_end_ind)*ppd;
                
                % Which target was closer to the saccade end position?
                % Get absolute distance of saccade end position from target centers
                delta_left = sqrt((sx-tl_x)^2 + (sy-tl_y)^2);
                delta_right = sqrt((sx-tr_x)^2 + (sy-tr_y)^2);
                
                % For Ben, the target radius used in the actual experiment was 100 pixels
                % more that the targetRadius parameter saved in matlab. This additional
                % 100 pixels comes from a constant added in the Fixated Autoadjust.vi
                
                if delta_left < (targ_rad +100)
                    tuple.resp_dir = 0;
                    tuple.resp_dir_str = 'left';
                elseif delta_right < (targ_rad + 100)
                    tuple.resp_dir = 1;
                    tuple.resp_dir_str = 'right';
                else
                    warning('Saccade did not land inside target')
                end
            end
            self.insert(tuple)
        end
    end
end
