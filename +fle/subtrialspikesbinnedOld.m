% fle.SubTrialSpikesBinned - Binned spikes for subtrials of flash lag experiment
% MS 2012-02-03
%{
fle.SubTrialSpikesBinned (computed) # my newest table
-> fle.Phys
-> fle.SubTrials
-> fle.SpikeBinParams
-----
spike_counts=NULL : mediumblob # number of spikes in each bin
%}

classdef SubTrialSpikesBinned < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.SubTrialSpikesBinned')
    end
    properties
        % Populate for each unit_id for each spike aligning condition for each fle experiment session.
        popRel = fle.Phys(fle.SubTrials) * fle.SpikeBinParams;
    end
    
    methods
        function self = SubTrialSpikesBinned(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            % Get spikes for a single/multi unit for the whole session
            spikeTrain = fetch1(ephys.Spikes(key),'spike_times');
            
            % Find stim on/off times for all subtrials in the given session (=key)
            [onsets offsets subtrialNums] = fetchn(fle.SubTrials(key),'substim_on','substim_off',...
                'subtrial_num');
            
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
            parfor iSub = 1:nSubTrials
                keys(iSub).subtrial_num = subtrialNums(iSub);
                spikes = spikeTrain(spikeTrain >= tStart(iSub) & spikeTrain < tEnd(iSub));%#ok
                % do the binning
                b = find(spikes > winStarts(iSub),1,'first');
                e = find(spikes < winEnds(iSub),1,'last');
                bins = winStarts(iSub):binWidth:winEnds(iSub);
                binned = histc(spikes(b:e),bins);
                keys(iSub).spike_counts = sparse(binned(1:end-1));
            end
            
            fprintf(' Inserting -->')
            self.insert(keys)
            fprintf(' Done (%0.2f sec)\n\n',toc);
        end
    end
end