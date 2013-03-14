%{
sess.VisArea (manual) # Stimulus parameters optimized for V1 or V2?
-> acq.Stimulation

---
vis_area_num = 0: tinyint unsigned # session params optimized for v1,v2,v3 or v4?
%}

classdef VisArea < dj.Relvar

	properties(Constant)
		table = dj.Table('sess.VisArea')
	end

	methods
		function self = VisArea(varargin)
			self.restrict(varargin)
		end
	end
end
