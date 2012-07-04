%{
rf.FitAvg (computed) # my newest table
-> rf.MapAvg
-----
cen_x : double # rf center x
cen_y : double # rf center y
fit_params : tinyblob # gaussian fit params
residuals: mediumblob # fit residuals
%}

classdef FitAvg < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.FitAvg')
    end
    properties
        popRel = rf.MapAvg  % !!! update the populate relation
    end
    
    methods
        function self = FitAvg(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            
            map = fetch1(rf.MapAvg(key),'map');
            [xGrid yGrid] = getGrid(rf.Map(key),'deg');
            
            % apply smoothing
            n = 5;
            w = window(@gausswin,n);
            w = w * w';
            w = w / sum(w(:));
            smap = imfilter(map,w,'circular');
            
            [x,y] = meshgrid(xGrid,yGrid);
            
            x = x(:); y = y(:); z = smap(:);
            xy = [x y]';
            
            [~, maxInd] = max(z);
            
            % Put initial guess for 2d gaussian params
            % Since we usually have the mapping grid centered around the approximate
            % receptive field location, we will take the grid center as initial rf
            % center.
            meanX = xy(1,maxInd);
            meanY = xy(2,maxInd);
            
            % We guess that the receptive field is oriented along cardinal axes
            covXY = 0;
            
            % Variance along each axis - guess 0.2 deg receptive field
            % diameter and that the receptive field is not elongated.
            rfDia = 0.2;
            varX = rfDia^2;
            varY = varX;
            
            gain = 1;
            
            initGuess = [meanX meanY varX varY covXY gain];
            
            lb = [-5 -5 0 0 0 0]; % lower bounds in the order [meanX meanY varX varY covXY  gain]
            ub = [10 10 10 10 5 1000];
            opt = optimset('Display','off','MaxFunEvals',1e8,'MaxIter',1e8,'TolFun',1e-9);
            [fitPar , ~, residuals] = lsqcurvefit(@rf.Fit.gauss,initGuess,xy,z',lb,ub,opt);
            
            % For now, we will try fitting inverse gaussian only for Diff map
            if key.map_type_num==4
                % Try inverted gaussian fit for inhibitory receptive fields
                [~, minInd] = min(z);
                meanX = xy(1,minInd);
                meanY = xy(2,minInd);
                initGuess = [meanX meanY varX varY covXY gain];
                [fitPar2 , ~, residuals2] = lsqcurvefit(@rf.Fit.invGauss,initGuess,xy,z',lb,ub,opt);
                
                % Selecte one vs the other using the percentage of variance reduced by
                % the model.
                expected = residuals + z';
                varRed1 = 100 * var(expected)/var(z);
                
                expected = residuals2 + z';
                varRed2 = 100 * var(expected)/var(z);
                fprintf('mapType: %s exc: %0.0f inhi: %0.0f\n',key.map_type_num,varRed1,varRed2);
                if varRed2 > varRed1
                    residuals = residuals2;
                    fitPar = fitPar2;
                end
            end
            key.cen_x = fitPar(1);
            key.cen_y = fitPar(2);
            key.fit_params = fitPar;
            key.residuals = residuals;
            self.insert(key)
        end
        
       function diaDeg = getSize(self,mahalDist)
            %         function diaDeg = getSize(self,mahalDist)
            if nargin < 2
                mahalDist = 1;
            end
            keys = fetch(self);
            nKeys = length(keys);
            diaDeg = nan(1,nKeys);
            iKey = 0;
            for key = keys'
                iKey = iKey + 1;
                fit_params = fetch1(rf.FitAvg(key),'fit_params');
                covMat = [fit_params(3) fit_params(5); fit_params(5) fit_params(4)];
                
                % Get the major and minor axis for the ellipse of gaussian receptive field
                [~,eigVal]=eig(covMat);
                eigVal(eigVal<0) = 0;
                halfAxisLen = sqrt(diag(eigVal)); % Equal to one std along each principal axis
                % Pick the major axis length as receptive field size
                diaDeg(iKey)  = max(mahalDist * halfAxisLen * 2);
            end
        end
        
        function [ox oy] = getOutline(self,mahalDist)
%       function [ox oy] = getOutline(self,mahalDist)

            if nargin < 2
                mahalDist = 1;
            end
            
            fit_params = fetch1(self,'fit_params');
            covMat = [fit_params(3) fit_params(5); fit_params(5) fit_params(4)];
            mx = fit_params(1);
            my = fit_params(2);
            
            % Create unit circle points for rescaling later using the eigen values
            npts = 50;
            tt = linspace(0,2*pi,npts)';
            x = cos(tt);
            y = sin(tt);
            xy = [x(:) y(:)]';
            
            % Get the major and minor axis for the ellipse of gaussian receptive field
            [eigVec,eigVal]=eig(covMat);
            eigVal(eigVal<0) = 0;
            halfAxisLen = sqrt(eigVal); % Equal to one std along each principal axis
            d = mahalDist * halfAxisLen;
            
            % Project unit circle points in Euclidean space to the eigen space
            % and scale it by std values along the principal axis.
            outline = (eigVec * d * xy) + repmat([mx;my], 1, npts);
            ox = outline(1,:);
            oy = outline(2,:);
        end
        
        function varargout = plot(self,varargin)
            
            arg.smooth = 5;
            arg.axis = [];
            arg.mahalDist = 1;
            arg = parseVarArgs(arg,varargin{:});
            
            % get all map data
            key = fetch(self);
            md = fetch(rf.MapAvg(key),'*');
            
            % get grid
            [x y] = getGrid(rf.Map(key),'deg');
            
            if ~isempty(arg.axis)
                axes(arg.axis)
            end
            
            % smooth map
            w = gausswin(arg.smooth);
            w = w*w';
            w = w/sum(w(:));
            map = imfilter(md.map,w,'same');
            
            % plot map
            h = imagesc(x,y,map);
            hold on
            if size(map,1)==size(map,2)
                PlotTools.sqAx;
            end
            axis image
            set(gca,'YDir','reverse','FontSize',7)
            
            if nargout
                varargout{1} = h;
            end
            % plot meridians
            plot(xlim,[0 0],'w');
            plot([0 0],ylim,'w');
            
            hold on
            % Plot outline of receptive field now.
            [ox oy] = getOutline(self,arg.mahalDist);
            plot(ox,oy,'w');
        end
    end
        
    methods(Static)
        
        function z = gauss(par,xy)
            covMat = [par(3) par(5); par(5) par(4)];
            x_u = [xy(1,:)-par(1);xy(2,:)-par(2)];
            % z = exp(-.5*sum(x_u.*(inv(covMat)*x_u),1)) * par(7) + par(6);
            %             z = exp(-.5*sum(x_u.*(covMat\x_u),1)) * par(7) + par(6);
            z = exp(-.5*sum(x_u.*(covMat\x_u),1)) * par(6);
        end
        
        function z = invGauss(par,xy)
            covMat = [par(3) par(5); par(5) par(4)];
            x_u = [xy(1,:)-par(1);xy(2,:)-par(2)];
            % z = (-exp(-.5*sum(x_u.*(inv(covMat)*x_u),1))) * par(7) + par(6);
            %             z = (-exp(-.5*sum(x_u.*(covMat\x_u),1))) * par(7) + par(6);
            z = (-exp(-.5*sum(x_u.*(covMat\x_u),1))) * par(6);
        end
    end
end

