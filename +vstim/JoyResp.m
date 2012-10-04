%{
vstim.JoyResp (computed) # joystick response data
-> vstim.TrialJoyTraces

-----
resp_dir=null: tinyint # 0 or 1 (0-left, 1-right, -1 noresponse)
resp_dir_str=null: enum('right','left','no_response') # direction moved
reaction_time=null: double # reaction time
%}

classdef JoyResp < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('vstim.JoyResp')
        popRel = vstim.TrialJoyTraces  % !!! update the populate relation
    end
    
    methods
        function self = JoyResp(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            tuple = key;
            %!!! compute missing fields for key here
            d = fetch(vstim.TrialJoyTraces(key),'*');
            h = d.trace_h_volt;
            gw = getGausswin(25,1000/d.sampling_rate);
            h = conv(h,gw,'same');
            h([1:20 end-20:end]) = NaN;
            % get baseline during the first 100 msec after stim onset
            rel_t = getRelTime(vstim.TrialJoyTraces(key));
            %             ind = rel_t > 0 & rel_t < 75;
            %             baseline = mean(h(ind));
            baseline = 2.3; % volt
            %             std_baseline = std(h(ind));
            
            % get reaction time
            %             h_rt = h-baseline;
            %             h_rt(rel_t < 0) = 0;
            
            %             tuple.reaction_time = rel_t(find(abs(h_rt) > min(0.05,100*std_baseline),1,'first'));
            delta = 0.125; % change in volts
            
            hh = abs(h-baseline);
            %             th = 0.1; % volts change
            
            
            ns = round(0.6 * d.sampling_rate);
            pulse_start = find(hh > delta,1,'first');
            
            if ~isempty(pulse_start)
                tuple.reaction_time = rel_t(pulse_start);
                
                
                %             % debug
                %             plot(rel_t,h);
                %             hold on
                %             plot(tuple.reaction_time,h(pulse_start),'rO')
                %
                
                
                hh((pulse_start + ns):end) = 0;
                [~, pk_ind] = max(hh);
                pk_volt = h(pk_ind);
                
                if pk_volt > (baseline + delta)
                    tuple.resp_dir_str = 'right';
                    tuple.resp_dir = 1;
                elseif pk_volt < (baseline - delta)
                    tuple.resp_dir_str = 'left';
                    tuple.resp_dir = 0;
                else
                    tuple.resp_dir_str = 'no_response';
                    tuple.resp_dir = -1;
                end
            end
            self.insert(tuple)
        end
    end
end
