%{
rf.SnrFitAvg (computed) # my newest table
-> rf.FitAvg
-----
snr: double # signal to noise ratio
%}

classdef SnrFitAvg < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.SnrFitAvg')
        popRel = rf.FitAvg  % !!! update the populate relation
    end
    
    methods
        function self = SnrFitAvg(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)
        function makeTuples(self, key)
            nMahDistForSNR = 1;
            fd = fetch1(rf.FitAvg(key),'fit_params');
            cx = fd(1);
            cy = fd(2);
            covMat = [fd(3) fd(5); fd(5) fd(4)];
            
            [x y] = getGrid(rf.Map(key),'deg');
            
            [xm ym] = meshgrid(x,y);
            allLocs = [xm(:) ym(:)]';
            
            % Compute mahalanobis distance of all pixels to the center
            md = util.mahalDist(allLocs,cx,cy,covMat);
            
            % Reshape output vector to rectangular array
            n = length(x); m = length(y);
            md = reshape(md,n,m);
            
            map = fetch1(rf.MapAvg(key),'map');
            absSig = abs(mean(map(md <= nMahDistForSNR)));
            noise = std(map(md > nMahDistForSNR));
            
            snr = absSig/noise;
            if isnan(snr)
                snr = 0;
            end
            key.snr = snr;
            self.insert(key)
        end
    end
end

