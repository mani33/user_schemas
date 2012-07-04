%{
rf.Size (computed) # my newest table
-> rf.FitAvg
-> rf.SizeParams
-----
size = -1: double # rf size in degrees

%}

classdef Size < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.Size')
    end
    properties
        popRel = rf.FitAvg * rf.SizeParams % !!! update the populate relation
    end
    
    methods
        function self = Size(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            fit_params = fetch1(rf.FitAvg(key),'fit_params');
            covMat = [fit_params(3) fit_params(5); fit_params(5) fit_params(4)];
            
            % Get the major and minor axis for the ellipse of gaussian receptive field
            [~,eigVal]=eig(covMat);
            eigVal(eigVal<0) = 0;
            halfAxisLen = sqrt(diag(eigVal)); % Equal to one std along each principal axis
            
            % Pick the major axis length as receptive field size
            key.size  = max(key.mahal_dist * halfAxisLen * 2);
            self.insert(key)
        end
    end
end
