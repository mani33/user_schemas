%{
fle.StRfParams (lookup) # my newest table

bar_cen_spacing_pix   : double          # In conjuntion with bar_width, will decide bin_width
bin_width: double # bin_width in msec
-----



strfparams_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef StRfParams < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.StRfParams')
	end

	methods
		function self = StRfParams(varargin)
			self.restrict(varargin{:})
		end
	end
end
