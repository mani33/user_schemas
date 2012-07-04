% fle.BinWidth - my newest table
% I will explain what my table does here 

%{
fle.BinWidth (lookup) # my newest table
bin_width = 10:  double # bin width in msec
-----

%}

classdef BinWidth < dj.Relvar

	properties(Constant)
		table = dj.Table('fle.BinWidth')
	end

	methods
		function self = BinWidth(varargin)
			self.restrict(varargin)
		end
	end
end
