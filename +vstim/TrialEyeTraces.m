%{
vstim.TrialEyeTraces (imported) # my newest table
-> acq.Stimulation
-> vstim.EyeTraceParams
-> vstim.PixPerDeg
trial_num       : int                   # trial number

-----
trace_h_deg: blob # horizontal eye trace in degrees
trace_v_deg: blob # vertical eye trace in degrees
sampling_rate: double # sampling rate in Hz
rel_t_start: double # trace starting time(msec) relative to stim onset
%}

classdef TrialEyeTraces < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('vstim.TrialEyeTraces')
        popRel = acq.Stimulation * vstim.EyeTraceParams * vstim.PixPerDeg% !!! update the populate relation
    end
    
    methods
        function self = TrialEyeTraces(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            % !!! compute missing fields for key here
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
                fileType = 'tdms';
            else
                error('Analog data file does not exist or of unknown file type')
            end
            
            channelNames = {'Eye Horizontal', 'Eye Vertical'};
            
            switch fileType
                case 'hdf5'
                    baseReaderFile = fullfile(getLocalPath(folder),'waveforms%u');
                    filePointer = baseReaderBehOld(baseReaderFile,channelNames);
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
            pix_per_deg = fetch1(vstim.PixPerDeg(key),'pix_per_deg');
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
                ep = tp.eyeParams;
                % get eye movements for current trial
                from = onsetTime - tuple.pre_stim_time;
                to = offsetTime + tuple.post_stim_time;
                
                if iTrial==nTrials
                    if to >= goodTimeEnd
                        to = goodTimeEnd;
                    end
                end
                [x, y, t] = vstim.TrialEyeTraces.getEyeData(from,to,channelNames,Fs,filePointer);
                x = decimate(x,tuple.decimation_fac,'FIR');
                y = decimate(y,tuple.decimation_fac,'FIR');
                tuple.trace_h_deg = (ep(1) + ep(2)* x)/pix_per_deg;
                tuple.trace_v_deg = (ep(3) + ep(4) *y)/pix_per_deg;
                tuple.rel_t_start = t(tuple.decimation_fac) - onsetTime;
                
                self.insert(tuple)
                displayProgress(iTrial,nTrials)
            end
        end
    end
    methods
        function plotChan(self,varargin)
            args.h = true;
            args.v = true;
            args.d = true;
            args.pause = true;
            args.markSaccade = true;
            args = parseVarArgs(args,varargin{:});
            
            keys = fetch(self);
            d = fetch(self,'*');
            nTrials = length(d);
            ms_figure(12221)
            set(gcf,'Position',[25,201,1231,443])
            for iTrial = 1:nTrials
                key = keys(iTrial);
                dd = d(iTrial);
                holdFixTime = fetch1(flebm.Trials(dd),'hold_fixation_time');
                h = dd.trace_h_deg;
                v = dd.trace_v_deg;
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
                plot(-[holdFixTime holdFixTime],ylim,'Color',[0.7 0.7 0.7])
                
                if args.markSaccade
                    if count(vstim.FirstSaccade(dd))==1
                        [on, off]  = fetchn(vstim.FirstSaccade(key),'sac_onset_rel_time','offset_rel_t');
                        plot([on on],ylim,'m');
                        plot([off off],ylim,'m');
                    end
                end
                if args.pause
                    pause
                    hold off
                end
            end
            mlegend([ph1 ph2],{'h','v'})
        end
        
        function plot(self,varargin)
            args.plot3 = true;
            args = parseVarArgs(args,varargin{:});
            keys = fetch(self);
            d = fetch(self,'*');
            nTrials = length(d);
            for iTrial = 1:nTrials
                dd = d(iTrial);
                holdFixTime = fetch1(flebm.Trials(dd),'hold_fixation_time');
                h = dd.trace_h_deg;
                v = dd.trace_v_deg;
                %                 Fs = dd.sampling_rate;
                %                 t_s = dd.rel_t_start;
                %                 n = length(h);
                key = keys(iTrial);
                t = getRelTime(vstim.TrialEyeTraces(key));
                
                if args.plot3
                    plot3(h,v,t,'k');
                else
                    plot(h,v,'k');
                end
                hold on
                
            end
        end
        
        function rel_t = getRelTime(self)
            dd = fetch(self,'*');
            t_s = dd.rel_t_start;
            h = dd.trace_h_deg;
            n = length(h);
            rel_t = linspace(t_s,1000*n/dd.sampling_rate,n);
        end
    end
    methods(Static)
        function [x, y, t] = getEyeData(from,to,chanNames,Fs,filePointer)
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
        function samples = getSamplesTDMS(requestedChanNames,startTimeInMsec,segLength,samplingRate,fileHandle)
            % function samples = getSamplesTDMS(requestedChanNames,startTimeInMsec,segLength,samplingRate,fileHandle)
            % Mani Subramaniyan
            % 26-April-2008
            
            % Get TDM Channel Group id
            pGroup = libpointer('int32Ptr',0);
            calllib('nilibddc','DDC_GetChannelGroups',fileHandle.Value,pGroup,1);
            
            % Get the number of channels
            pChanNum = libpointer('uint32Ptr', 0);
            calllib('nilibddc', 'DDC_GetNumChannels', pGroup.Value, pChanNum);
            
            % Get TDMS Channel ids
            pChannel = libpointer('int32Ptr',1:pChanNum.Value);
            calllib('nilibddc','DDC_GetChannels',pGroup.Value,pChannel,pChanNum.Value);
            
            % Get channel names
            len = libpointer('uint32Ptr',0);
            allChanNames = cell(1,pChanNum.Value);
            for i = 1:pChanNum.Value
                % Get the length of the channel name string.
                calllib('nilibddc', 'DDC_GetChannelStringPropertyLength', pChannel.Value(i),'Name',len);
                
                % Read the name of the channel
                name = libpointer('uint8Ptr',1:len.Value);
                calllib('nilibddc', 'DDC_GetChannelProperty', pChannel.Value(i),'Name',name,len.Value+1);
                allChanNames{i} = char(name.Value);
            end
            
            % Find out the indices of the requested channels:
            [c, reqChanInd] = intersect(allChanNames,requestedChanNames);
            if ischar(requestedChanNames)% when a single channel is requested
                nc = 1;
            else
                nc = numel(requestedChanNames);% when a cell array of strings are given
            end
            if numel(reqChanInd) ~= nc
                error('One or more given channel names do not exist in the data');
            end
            
            pDataType = libpointer('int32Ptr',0);
            pDataLen = libpointer('uint32Ptr',0);
            
            nChans = numel(reqChanInd);
            % Get the number of samples to read
            nSamples = samplingRate * segLength/1000;
            start =  samplingRate * startTimeInMsec/1000;
            
            samples = cell(1,nChans);
            
            for chan = 1:nChans
                currentChanInd = reqChanInd(chan);
                currentChanHandle = pChannel.Value(currentChanInd);
                % Get the Channel data type
                calllib('nilibddc','DDC_GetDataType',currentChanHandle,pDataType);
                switch pDataType.Value
                    case 2,  dataType = 'int16Ptr';
                    case 3,  dataType = 'int32Ptr';
                    case 5,  dataType = 'uint8Ptr';
                    case 9,  dataType = 'singlePtr';
                    case 10, dataType = 'doublePtr';
                    case 23, dataType = 'stringPtr';
                end
                
                % Get the Channel data length
                calllib('nilibddc','DDC_GetNumDataValues',currentChanHandle,pDataLen);
                
                % Throw error if the requested sample is outside the data range
                if start > pDataLen.Value
                    error('The requested samples are outside the range of available data');
                end
                
                % Truncate the nSamples if all the requested samples are not available
                available = pDataLen.Value - start +1;
                if nSamples > available
                    nSamples = available;
                end
                pdata = libpointer(dataType,uint32(1:nSamples));
                % Get all the data in the Channel
                calllib('nilibddc','DDC_GetDataValues',currentChanHandle,start,nSamples,pdata);
                samples{i} = pdata.value;
            end
        end
        
        function fileHandle = loadTdmsData(fileName)
            % function fileHandle = loadTdmsData(fileName)
            %
            % Mani Subramaniyan
            % 26-April-2008
            %
            % INPUTS:
            % fileName  - absolute file name.
            %
            % OUTPUTS:
            % fileHandle - pointer to the opened file.
            %--------------------------------------------------------------------------
            
            % If the data file is not loaded, load it
            if ~libisloaded('nilibddc')
                %--------------------------------------------------------------------------
                % Load DIAdem Connectivity Library
                fold = 'z:\libraries\tdms';
                examplePath = fullfile(fold,'bin');
                hfile = fullfile(examplePath,'nilibddc_m.h');
                loadlibrary(fullfile(examplePath,'nilibddc'),hfile);
                
                addpath('z:\libraries\tdms');
                addpath('z:\libraries\matlab');
            end
            %--------------------------------------------------------------------------
            % Open the TDMS file
            fileHandle = libpointer('int32Ptr',0);
            if calllib('nilibddc','DDC_OpenFileEx',fileName,'TDMS',1,fileHandle) ~= 0
                error('TDM-file could not be loaded!');
            end
            %----------------------------------------------------------------------
        end
    end
end
