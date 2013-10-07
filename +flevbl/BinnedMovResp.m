%{
flevbl.BinnedMovResp (computed) # trial-wise binned spike count for moving stimuli
-> flevbl.SubTrialSpikes
-> flevbl.MovBw
-----
bin_width : double # actual bin width in ms

%}

classdef BinnedMovResp < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.BinnedMovResp')
        popRel = (flevbl.SubTrialSpikes & flevbl.StimCond('is_moving = 1') & (flevbl.Traj | flevbl.TrajControls)) * flevbl.MovBw % !!! update the populate relation
    end
    
    methods
        function self = BinnedMovResp(varargin)
            self.restrict(varargin)
        end
    end
    
    methods(Access=protected)
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
        end
    end
end
