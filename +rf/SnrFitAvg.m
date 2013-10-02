%{
rf.SnrFitAvg (computed) # my newest table
-> rf.FitAvg
-> rf.SnrParams
-----
snr: double # signal to noise ratio
%}

classdef SnrFitAvg < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.SnrFitAvg')
        popRel = rf.FitAvg * rf.SnrParams  % !!! update the populate relation
    end
    
    methods
        function self = SnrFitAvg(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access=protected)
        function makeTuples(self, key)
            nMahDistForSNR = key.mahal_dist;
            fd = fetch1(rf.FitAvg(key),'fit_params');
            cx = fd(1);
            cy = fd(2);
            covMat = [fd(3) fd(5); fd(5) fd(4)];
            
            [x, y] = getGrid(rf.Map(key),'deg');
            
            [xm, ym] = meshgrid(x,y);
            allLocs = [xm(:) ym(:)]';
            
            % Compute mahalanobis distance of all pixels to the center
            md = util.mahalDist(allLocs,cx,cy,covMat);
            
            % Reshape output vector to rectangular array
            n = length(x); m = length(y);
            md = reshape(md,n,m);
            
            map = fetch1(rf.MapAvg(key),'map');
            % apply smoothing
            n = 5;
            w = window(@gausswin,n);
            w = w * w';
            w = w / sum(w(:));
            smap = imfilter(map,w,'circular');
            
            absSig = abs(mean(smap(md <= nMahDistForSNR)));
            noise = std(smap(md > nMahDistForSNR));
            
            snr = absSig/noise;
            if isnan(snr)
                snr = 0;
            end
            key.snr = snr;
            self.insert(key)
        end
    end
end

