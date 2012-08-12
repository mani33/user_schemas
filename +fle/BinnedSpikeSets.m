% fle.BinnedSpikeSets - my newest table
% I will explain what my table does here

%{
fle.BinnedSpikeSets (computed) # my newest table
-> fle.Phys
-> fle.SpikeBinParams
-----
binnedspikesets_ts = CURRENT_TIMESTAMP: timestamp  # do not edit
%}

classdef BinnedSpikeSets < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.BinnedSpikeSets')
        popRel = fle.Phys * fle.SpikeBinParams;  % !!! update the populate relation
    end
    methods
        function self = BinnedSpikeSets(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % Populate subtables
            makeTuples(fle.SubTrialSpikesBinned,key);
        end
    end
    methods
        function binIndices = getBinIndicesForInterval(self,interval)
            % Return bin indices for given time interval.
            %   bins = getBinsForInterval(spikes,interval) where interval is a
            %   two-element vector containing the beginning and end of the interval
            %   relative to substimulus onset.
            %
            % AE 2010-02-01/MS 2012-02-06
            p = fetch(self);
            preBins = ceil(p.pre_stim_time / p.bin_width);
            b = interval / p.bin_width + preBins;
            binIndices = (fix(b(1)) + 1) : ceil(b(2));
        end
        
    end
end
