% fle.FlashRfFit - my newest table
% I will explain what my table does here

%{
fle.FlashRfFit (computed) # my newest table
-> fle.FlashRf
-> fle.FlashRfFitParams
-----
fit_params = Null: tinyblob # array of fitted parameters
resid = Null: tinyblob # array of residuals of the fit
%}

classdef FlashRfFit < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.FlashRfFit')
        fit_fun = '@(b,x) b(1) + b(2) * exp(-(x - b(3)).^2 / (2*(b(4)^2)))';
    end
    properties
        popRel = fle.FlashRf * fle.FlashRfFitParams
    end
    
    methods
        function self = FlashRfFit(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            
            d = fetch(fle.FlashRf(key),'base');
            sm = getSpatialMap(fle.FlashRf(key),key.resp_win_start,key.resp_win_end);
            
            x = 1:size(sm,2);
            opt = optimset('display','off');
            a(1) = d.base;
            [a(2),a(3)] = max(sm);
            a(2) = a(2) - a(1);
            a(4) = 1;
            yi = sm;
            
            key.fit_params = lsqcurvefit(@fle.FlashRfFit.gauss,a,x,yi,[],[],opt);
            key.resid = (fle.FlashRfFit.gauss(key.fit_params,x) - yi) / norm(yi);
            
            self.insert(key)
        end
        
        function [b fn res] = getFitData(self)
            x = fetch(self,'fit_params','resid');
            b = x.fit_params;
            res = x.resid;
            fn = self.fit_fun;
        end
        
        function p = getSignificanceOfFit(self)
            
            fd = fetch(self,'fit_params');
            rp = fetch(fle.FlashRf(self),'flash_centers');
            r = getSpatialMap(fle.FlashRf(self),fd.resp_win_start,fd.resp_win_end);
            
            n = numel(r);
            
            % ANOVA testing
            x = 1:length(rp.flash_centers);
            fn = str2func(self.fit_fun);
            rhat = fn(fd.fit_params,x);
            
            SSerror = sum((r - rhat).^2);
            SSmodel = sum(rhat.^2);
            dfm = 4;
            dfe = n - dfm - 1;
            
            MSerror = SSerror / dfe;
            MSmodel = SSmodel / dfm;
            
            F = MSmodel / MSerror;
            
            p = 1 - fcdf(F,dfm,dfe);
        end
    end
    methods(Static)
        function y = gauss(b,x)
            y = b(1) + b(2) * exp(-(x - b(3)).^2 / (2*(b(4)^2)));
        end
    end
end
