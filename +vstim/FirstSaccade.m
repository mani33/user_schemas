%{
vstim.FirstSaccade (computed) # my newest table

-> vstim.TrialEyeTraces
---
sac_onset_rel_time=null     : double                        # saccade onset time relative to stimulus onset
sac_offset_rel_time=null    : double                        # saccade offset time relative to stimulus onset
%}

classdef FirstSaccade < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('vstim.FirstSaccade')
        popRel = vstim.TrialEyeTraces  % !!! update the populate relation
    end
    
    methods
        function self = FirstSaccade(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            tuple = key;
            %!!! compute missing fields for key here
            sacc_latency = 300; % msec before a saccade is initiated
            saccAmpTh = 1; % deg displacement from fixation to qualify as a saccade
            thDegPerSec = 50; % deg/sec speed threshold
            smoothStdMsec = 20; % gaussian window smoothing std
            [h v] = fetchn(vstim.TrialEyeTraces(key),'trace_h_deg','trace_v_deg');
            d = sqrt(h{:}.^2 + v{:}.^2); % distance in deg
            Fs = fetch1(vstim.TrialEyeTraces(key),'sampling_rate');
            rel_t = getRelTime(vstim.TrialEyeTraces(key));
            d(rel_t < 0) = 0;
            subject = fetch1(acq.Subjects(key),'subject_name');
            switch subject
                case 'Hulk'
                    % Dimitri's idea
                    sacFreq = 1000/(2*sacc_latency);
                    T = Fs/sacFreq;
                    n = floor(T/2);
                    k = hamming(n);
                    k = [k;0;-k]/sum(k);
                    x = fftfilt(k,[double(d);zeros(n,1)]);
                    x = x(n+1:end);
                    x([1:n end+[-n+1:0]])=0;%#ok
                    x = abs(x);
                    % select flips
                    flips = spaced_max(x,0.45*T);
                    thresh = 0.25*quantile( x(flips), 0.99);
                    idx = find(x(flips)>thresh);
                    if ~isempty(idx)
                        saccMidInd = flips(idx(1));
                        % Get the onset time
                        % Go about 100 msec before the saccade mid point and detect the point when
                        % the saccade was initiated
                        np = round(0.1*Fs);
                        start = saccMidInd - np;
                        % Get speed
                        sp = diff(d)/(1/Fs);
                        % Smooth the speed
                        gw = getGausswin(smoothStdMsec,1000/Fs);
                        sp = conv(sp,gw,'same');
                        ss = sp;
                        ss(1:start) = 0;
                        saccStart = find(ss > thDegPerSec,1,'first');
                        nsp = round(0.04*Fs);
                        if ~isempty(saccStart)
                            disp(mean(d((1:nsp)+saccStart)))
                            if mean(d((1:nsp)+saccStart)) > saccAmpTh
                                % Go back by about 10 msec worth to capture the period when the monkey
                                % initiated a saccade
                                nEdge = round(0.01*Fs);
                                saccStart = saccStart - nEdge;
                                
                                % Take the curved saccade into account
                                % Go about 200 msec after saccade midpoint
                                np = round(0.2*Fs);
                                sc = ss;
                                saccEnd  = saccStart + np;
                                if saccEnd <= length(ss)
                                    sc(saccEnd:end) = 0;
                                    saccEnd = find(abs(sc) > thDegPerSec,1,'last');
                                    saccEnd = saccEnd + nEdge;
                                    tuple.sac_offset_rel_time = rel_t(saccEnd);
                                end
                                
                                tuple.sac_onset_rel_time = rel_t(saccStart);
                            end
                        end
                    end                    
                case 'Ben'
                    % Use simple threshold strategy for Ben where we used video camera for
                    % tracking
                    % smooth the distance trace first
                    gw = getGausswin(smoothStdMsec,1000/Fs);
                    ds = conv(d,gw,'same');
                    s = diff(ds)/(1/Fs);
                    speedTh = 100; % deg/s
                    start = find(s > speedTh,1,'first');
                    if ~isempty(start)
                        % saccade should be over in 50 msec
                        np = round(0.05*Fs);
                        st = s;
                        sacOn = start + np;
                        if sacOn < length(d)
                            st(sacOn:end) = 0;
                            endd = find(st > speedTh,1,'last');
                            % Go 1 times the width at midpoint of speed profile
                            hw = round((endd - start)/2);
                            start = start - hw;
                            if start > 0
                                tuple.sac_onset_rel_time = rel_t(start);
                            end
                            if ~isempty(endd)
                                endd = endd + hw;
                                if endd <= length(d)
                                    tuple.sac_offset_rel_time = rel_t(endd);
                                end
                            end
                        end
                    end
                otherwise
                    error('Subject %s is unsupported',subject)
            end
            self.insert(tuple)
        end
    end
    methods
        function plot(self,varargin)
            %       function plot(self,varargin)
            % Plots fixated period with or without the first saccade
            args.tStart = 0;
            args.fixated = true;
            args.saccade = false;
            args.type = 'hv'; % {'hv','hAndV','3d'}
            args.raster = true;
            args.offset = 0.25; % deg vertical offset to add to raster plot
            args = parseVarArgs(args,varargin{:});
            tuples = fetch(self,'*');
            offset = 0;
            for key = tuples'
                tet = vstim.TrialEyeTraces(key);
                [h v] = fetchn(tet,'trace_h_deg','trace_v_deg');
                h = h{:};
                v = v{:};
                t = getRelTime(tet);
                offset = offset + args.offset;
                if args.fixated && args.saccade
                    % Cut off the trace at the end of the first saccade
                    selInd = t >= args.tStart & t < key.sac_offset_rel_time;
                    h = h(selInd);
                    v = v(selInd);
                elseif args.fixated
                    % Cut off the trace at the beginning of the first saccade
                    selInd = t >= args.tStart & t < key.sac_onset_rel_time;
                    h = h(selInd);
                    v = v(selInd);
                elseif args.saccade
                    % Show only saccade
                    selInd = t > key.sac_onset_rel_time & t < key.sac_offset_rel_time;
                    h = h(selInd);
                    v = v(selInd);
                else
                    error('at least one of saccade or fixated should be true')
                end
                t = t(selInd)';
                h1 = [];
                if args.raster
                    v = v + offset;
                end
                switch args.type
                    case 'hv'
                        plot(h,v)
                    case 'hAndV'
                        h1 = plot(t,h,'r'); hold on
                        h2 = plot(t,v,'b');
                    case '3d'
                        plot3(h,v,t,'Color','k');
                        xlim([-2 2]);
                        ylim([-2 2])
                    otherwise
                        error('specify a plot type')
                end
                hold all
            end
            %             if ~isempty(h1)
            %                 mlegend([h1 h2],{'h','v'});
            %             end
        end
    end
end
