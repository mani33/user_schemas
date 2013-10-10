%{
fle.CombPsthParams (lookup) # my newest table

bar_cen_spacing_pix   : double          # In conjuntion with bar_width, will decide bin_width
peri_flash_time = 300: double # pre-flash time
direction: boolean # motion direction
-----



combpsthparams_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef CombPsthParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.CombPsthParams')
	end

	methods
		function self = CombPsthParams(varargin)
			self.restrict(varargin{:})
		end
	end
end
