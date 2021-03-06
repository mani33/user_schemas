%{
fle.PsthParams (lookup) # Params for fle.Psth 

bar_cen_spacing_pix   : double          # In conjuntion with bar_width, will decide bin_width

-----



psthparams_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef PsthParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.PsthParams')
	end

	methods
		function self = PsthParams(varargin)
			self.restrict(varargin{:})
		end
	end
end
