% fle.BarRfFit - my newest table
% I will explain what my table does here

%{
fle.BarRfFit (computed) # my newest table
-> fle.BarRf
-----
fit_params = Null: tinyblob # array of fitted parameters
resid = Null: tinyblob # array of residuals of the fit
%}

classdef BarRfFit < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.BarRfFit')
        fit_fun = '@(b,x) b(1) + b(2) * exp(-(x - b(3)).^2 / (2*(b(4)^2)))';
        popRel = fle.BarRf;
    end
    
    methods
        function self = BarRfFit(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            
            d = fetch(fle.BarRf(key),'base');
            sm = getSpatialMap(fle.BarRf(key));
            if any(isnan(sm))
                key.fit_params = nan(1,4);
                key.resid = nan;
            else
                x = 1:size(sm,2);
                opt = optimset('display','off');
                a(1) = d.base;
                [a(2),a(3)] = max(sm);
                a(2) = a(2) - a(1);
                a(4) = 1;
                yi = sm;
                lb = [0 0 0 0];
                ub = [1000 100 length(x) length(x)];
                if length(yi) > length(lb) % In one session, there were only 3 flash locations. You can't fit 4 parameters for a 3 point data set
                    key.fit_params = lsqcurvefit(@fle.BarRfFit.gauss,a,x,yi,lb,ub,opt);
                    key.resid = (fle.BarRfFit.gauss(key.fit_params,x) - yi) / norm(yi);
                end
            end
            self.insert(key)
        end
    end
    methods
        function [b fn res] = getFitData(self)
            x = fetch(self,'fit_params','resid');
            b = x.fit_params;
            res = x.resid;
            fn = self.fit_fun;
        end
        function cen = get_center(self)
            keys = fetch(self);
            fp = arrayfun(@(k) fetch1(fle.BarRfFit(k),'fit_params'), keys, 'uni',false);
            cen = cellfun(@(p) p(3), fp);
        end
        
        function p = getSignificanceOfFit(self)
            disp('Function needs revision')
            %             fd = fetch(self,'fit_params');
            %             rp = fetch(fle.BarRf(self),'flash_centers');
            %             r = getSpatialMap(fle.BarRf(self));
            %             r = r - mean(r);
            %             n = numel(r);
            %
            %             % Test significance
            %             % ANOVA testing
            %             % Model: (yi-ym) = (yhat-ym) + (yi - yhat) => SST = SSM + SSE
            %             x = 1:length(rp.flash_centers);
            %             fn = str2func(self.fit_fun);
            %             rhat = fn(fd.fit_params,x);
            %
            %             SSerror = sum((r - rhat).^2);
            %             SSmodel = sum((rhat - mean(r)).^2);
            %             dfm = 4;
            %             dfe = n - dfm;
            %
            %             MSerror = SSerror / dfe;
            %             MSmodel = SSmodel / dfm;
            %
            %             F = MSmodel / MSerror;
            %
            %             p = 1 - fcdf(F,dfm,dfe);
        end
    end
    methods(Static)
        function y = gauss(b,x)
            y = b(1) + b(2) * exp(-(x - b(3)).^2 / (2*(b(4)^2)));
        end
    end
end
