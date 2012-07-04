%{
rf.SnrFit (computed) # my newest table

-> rf.Fit
---
snr=null                    : double                        # signal to noise ratio
%}

classdef SnrFit < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.SnrFit')
    end
    properties
        popRel = rf.Fit  % !!! update the populate relation
    end
    
    methods
        function self = SnrFit(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            
            nMahDistForSNR = 1;
            fd = fetch1(rf.Fit(key),'fit_params');
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
            
            map = fetch1(rf.Map(key),'map');
            absSig = abs(mean(map(md <= nMahDistForSNR)));
            noise = std(map(md > nMahDistForSNR));
            
            snr = absSig/noise;
            if isnan(snr)
                snr = 0;
            elseif isinf(snr)
                snr = nan;
            end
            key.snr = snr;
            self.insert(key)
        end
    end
end
