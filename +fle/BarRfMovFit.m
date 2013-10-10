%{
fle.BarRfMovFit (computed) # my newest table
-> fle.BarRfMov

-----
fit_params = Null: tinyblob # array of fitted parameters
resid = Null: tinyblob # array of residuals of the fit
%}

classdef BarRfMovFit < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.BarRfMovFit')
        fit_fun = '@(b,x) b(1) + b(2) * exp(-(x - b(3)).^2 / (2*(b(4)^2)))';
        popRel = fle.BarRfMov  % !!! update the populate relation
    end
    
    methods
        function self = BarRfMovFit(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            
            d = fetch(fle.BarRfMov(key),'base');
            sm = getSpatialMap(fle.BarRfMov(key));
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
                key.fit_params = lsqcurvefit(@fle.BarRfMovFit.gauss,a,x,yi,lb,ub,opt);
                key.resid = (fle.BarRfMovFit.gauss(key.fit_params,x) - yi) / norm(yi);
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
    end
    methods(Static)
        function y = gauss(b,x)
            y = b(1) + b(2) * exp(-(x - b(3)).^2 / (2*(b(4)^2)));
        end
    end
end
