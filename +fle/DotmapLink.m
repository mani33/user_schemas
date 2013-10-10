% This table saves the DotMapping session electrode/unit keys from the recording session
% where Flash Lag Experiment was also conducted.
% MS 2012-04-01
%{
fle.DotmapLink (computed) # my newest table
-> fle.Phys
-----
dotmap_key = Null: blob # dotmapping experiment electrode key
%}

classdef DotmapLink < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.DotmapLink')
        popRel = fle.Phys;  % !!! update the populate relation
    end
    
    methods
        function self = DotmapLink(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            dmRv = acq.Sessions(key) * acq.Stimulation('exp_type = "DotMappingExperiment"');
            rfRv = rf.SpikeSets(dmRv,sprintf('unit_id = %u',key.unit_id));
            key.dotmap_key = fetch(rfRv);
            self.insert(key)
        end
    end
end
