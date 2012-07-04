%{
sess.SessVisArea (manual) # my newest table
-> acq.Sessions

---
v1 = 0: boolean # session params optimized for v1
v2 = 0: boolean # session params optimized for v2
v3 = 0: boolean # session params optimized for v3
v4 = 0: boolean # session params optimized for v4
%}

classdef SessVisArea < dj.Relvar

	properties(Constant)
		table = dj.Table('sess.SessVisArea')
	end

	methods
		function self = SessVisArea(varargin)
			self.restrict(varargin)
		end
	end
end
