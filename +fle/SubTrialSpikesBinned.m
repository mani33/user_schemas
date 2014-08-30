% fle.SubTrialSpikesBinned - my newest table
% I will explain what my table does here

%{
fle.SubTrialSpikesBinned (computed) # my newest table
-> fle.BinnedSpikeSets
subtrial_num     : int unsigned          # subTrial number

-----
spike_counts=NULL : mediumblob # number of spikes in each bin

%}

classdef SubTrialSpikesBinned < dj.Relvar
    
    properties(Constant)
        table = dj.Table('fle.SubTrialSpikesBinned')
    end
    
    methods
        function self = SubTrialSpikesBinned(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key) % Get spikes for a single/multi unit for the whole session
            spikeTrain = fetch1(ephys.Spikes(key),'spike_times');
            
            % Find stim on/off times for all subtrials in the given session (=key)
            [onsets, offsets, subtrialNums] = fetchn(fle.SubTrials(key),'substim_on','substim_off',...
                'subtrial_num');
            onsets = double(onsets);
            offsets = double(offsets);
            tStart = onsets - key.pre_stim_time;
            tEnd = offsets + key.post_stim_time;
            winSizes = tEnd-tStart;
            binWidth = key.bin_width;
            nBins = ceil(winSizes / binWidth);
            preBins = ceil(key.pre_stim_time / binWidth);
            winStarts = onsets - preBins * binWidth;
            winEnds = winStarts + nBins .* binWidth;
            
            % Go to each subtrial and pick spikes
            nSubTrials = length(onsets);
            keys = repmat(key,1,nSubTrials);
            
            tic
            fprintf('Computing tuples -->')
            for iSub = 1:nSubTrials
                keys(iSub).subtrial_num = subtrialNums(iSub);
                spikes = spikeTrain(spikeTrain >= tStart(iSub) & spikeTrain < tEnd(iSub));
                % do the binning
                b = find(spikes > winStarts(iSub),1,'first');
                e = find(spikes < winEnds(iSub),1,'last');
                bins = winStarts(iSub):binWidth:winEnds(iSub);
                binned = histc(spikes(b:e),bins);
                keys(iSub).spike_counts = reshape(binned(1:end-1),[],1);
            end
            
            fprintf(' Inserting -->')
            self.insert(keys)
            fprintf(' Done (%0.2f sec)\n\n',toc);
        end
        
        
        function smat = getSpikeMatrix(self,subTrials,binIndices)
            % Get all the available bins from each subTrial
            k = size(subTrials);
            smat = zeros(k(1),k(2),length(binIndices));
            for iRow = 1:k(1)
                for iCol = 1:k(2)
                    qs = sprintf('subtrial_num = %u',subTrials(iRow,iCol));
                    sc = fetchn((self & qs),'spike_counts');
                    sc = [sc{:}];
                    smat(iRow,iCol,:) = reshape(sc(binIndices),[],1);
                end
            end
        end
        
    end
end
