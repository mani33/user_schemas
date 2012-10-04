%{
vstim.TrialJoyTraces (imported) # my newest table
-> acq.Stimulation
-> vstim.JoyTraceParams
trial_num       : int                   # trial number
-----
trace_h_volt: blob # horizontal joystick trace in Volts
trace_v_volt: blob # vertical joystick trace in Volts
sampling_rate: double # sampling rate in Hz
rel_t_start: double # trace starting time(msec) relative to stim onset

%}

classdef TrialJoyTraces < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('vstim.TrialJoyTraces')
        popRel = acq.Stimulation * vstim.JoyTraceParams % !!! update the populate relation
    end
    
    methods
        function self = TrialJoyTraces(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            folder = fetch1(acq.Stimulation(key),'stim_path');
            % WARNING: the code was not tested to see if it handles the tdms data type
            % correctly since I was unable to read any tdms data due to compatibility
            % issues.
            
            % tdms or hdf5?
            hdfFile = fullfile(getLocalPath(folder),'waveforms0');
            tdmsFile = fullfile(getLocalPath(folder),'waveforms.tdms');
            
            
            if exist(hdfFile,'file')
                fileType = 'hdf5';
            elseif exist(tdmsFile,'file')
                error('tdms data type not supported')
            else
                error('Analog data file does not exist or of unknown file type')
            end
            
            channelNames = {'Joystick Horizontal', 'Joystick Vertical'};
            
            switch fileType
                case 'hdf5'
                    baseReaderFile = fullfile(getLocalPath(folder),'waveforms%u');
                    filePointer = baseReaderBehOld(baseReaderFile,channelNames);
                    if getNbChannels(filePointer)==1
                        channelNames = {'Joystick Horizontal', 'Joystick Joystick Vertical'};
                        filePointer = baseReaderBehOld(baseReaderFile,channelNames);
                    end
                    Fs = getSamplingRate(filePointer);
                    Fs_new = round(Fs/key.decimation_fac);
                    nbSamples = getNbSamples(filePointer);
                case 'tdms'
                    filePointer = loadTdmsData(tdmsFile);
                    nbSamples = inf;
                    Fs = 2000;
                    Fs_new = round(Fs/key.decimation_fac);
                otherwise
                    error('unknown file type')
            end
            
            goodTimeEnd = 1000 *(nbSamples)/Fs - 1; % in msec
            onData = fetch(stimulation.StimTrialEvents(key,'event_type = "showStimulus"') & ...
                stimulation.StimTrials('valid_trial = 1'),'event_time');
            offData = fetch(stimulation.StimTrialEvents(key,'event_type = "endStimulus"') & ...
                stimulation.StimTrials('valid_trial = 1'),'event_time');
            onTrialNum = [onData.trial_num];
            offTrialNum = [offData.trial_num];
            nTrials = length(onData);
            
            if length(onData)~=length(offData)
                warning('# of On and Off times doesn''t match. Using the last swapTime of a trial as "endStimulus" time')
            end
            
            for iTrial = 1:nTrials
                tuple = key;
                trialNum = onTrialNum(iTrial);
                tuple.trial_num = trialNum;
                tuple.sampling_rate = Fs_new;
                onsetTime = onData(iTrial).event_time;
                tp = fetch1(stimulation.StimTrials(key,sprintf('trial_num = %u',trialNum)),'trial_params');
                
                if isempty(offData)
                    % In some old sessions, event 'endStimulus' was absent. For those
                    % sessions, we will use the last swapTime of a trial as "endStimulus"
                    % time.
                    offsetTime = tp.swapTimes(end);
                else
                    offsetTime = offData(offTrialNum==trialNum).event_time;
                end
                % get eye movements for current trial
                from = onsetTime - tuple.pre_stim_time;
                to = offsetTime + tuple.post_stim_time;
                
                if iTrial==nTrials
                    if to >= goodTimeEnd
                        to = goodTimeEnd;
                    end
                end
                [x y t] = vstim.TrialJoyTraces.getJoyData(from,to,channelNames,Fs,filePointer);
                x = decimate(x,tuple.decimation_fac,'FIR');
                y = decimate(y,tuple.decimation_fac,'FIR');
                tuple.trace_h_volt = x;
                tuple.trace_v_volt = y;
                tuple.rel_t_start = t(tuple.decimation_fac) - onsetTime;
                
                self.insert(tuple)
                displayProgress(iTrial,nTrials)
            end
        end
    end
    
    
    methods
        function plot(self,varargin)
            args.pause = true;
            args = parseVarArgs(args,varargin{:});
            keys = fetch(self);
            d = fetch(self,'*');
            nTrials = length(d);
            figure(12231)
            for iTrial = 1:nTrials
                dd = d(iTrial);
                h = dd.trace_h_volt;
                v = dd.trace_v_volt;
                
                subplot(131)
                plot(h,v,'k');
                reaction_time = NaN;
                if count(vstim.JoyResp(keys(iTrial)))==1
                    rd = fetch(vstim.JoyResp(keys(iTrial)),'*');                    
                    title(sprintf('resp_dir = %s',rd.resp_dir_str));
                    reaction_time = rd.reaction_time;
                end
               
                rt = getRelTime(vstim.TrialJoyTraces(keys(iTrial)));
                
                subplot(132)
                plot(rt,h,'k')
                
                
                subplot(133)
                plot(rt,h,'b')
                hold on;
                plot(rt,v,'r')
                
                if ~isnan(reaction_time)
                    plot([reaction_time reaction_time],ylim,'k')
                end
                hold off
                
                if args.pause
                    pause
                end
            end
        end
        function plotChan(self,varargin)
            args.h = true;
            args.v = true;
            args.d = true;
            args.pause = true;
            args.markResponse = true;
            args = parseVarArgs(args,varargin{:});
            
            keys = fetch(self);
            d = fetch(self,'*');
            nTrials = length(d);
            ms_figure(12221)
            set(gcf,'Position',[25,201,1231,443])
            for iTrial = 1:nTrials
                key = keys(iTrial);
                dd = d(iTrial);
                h = dd.trace_h_volt;
                v = dd.trace_v_volt;
                Fs = dd.sampling_rate;
                t_s = dd.rel_t_start;
                n = length(h);
                t = linspace(t_s,1000*n/Fs,n);
                dis = sqrt(h.^2 + v.^2);
                if args.h
                    ph1 = plot(t,h,'r'); hold on
                end
                if args.v
                    ph2 = plot(t,v,'b');
                end
                if args.d
                    plot(t,dis,'k');
                end
                plot([0 0],ylim,'k')
                
                if args.markResponse
                    if count(vstim.JoyResp(dd))==1
                        rt  = fetch1(vstim.JoyResp(key),'reaction_time');
                        plot([rt rt],ylim,'m');
                    end
                end
                if args.pause
                    pause
                    hold off
                end
            end
            mlegend([ph1 ph2],{'h','v'})
        end
        
        
        
        function rel_t = getRelTime(self)
            dd = fetch(self,'*');
            t_s = dd.rel_t_start;
            h = dd.trace_h_volt;
            n = length(h);
            rel_t = linspace(t_s,1000*n/dd.sampling_rate,n);
        end
    end
    methods(Static)
        function [x y t] = getJoyData(from,to,chanNames,Fs,filePointer)
            fileClass = class(filePointer);
            switch fileClass
                case {'baseReader','baseReaderHammer','baseReaderBehOld'}
                    br = filePointer;
                    idx = getSampleIndex(br,[from to]);
                    x = br(idx(1):idx(2),1);
                    y = br(idx(1):idx(2),2);
                    t = br(idx(1):idx(2),'t');
                case 'tdms'
                    segDuration = to-from;
                    d = getSamplesTDMS(chanNames,from,segDuration,Fs,filePointer);
                    nSamples = round(segDuration * Fs/1000);
                    t = linspace(from,to,nSamples);
                    x = d{1};
                    y = d{2};
                otherwise
                    error('unknown file type')
            end
        end
    end
end