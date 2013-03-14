%{
sess.WrongTetMap (manual) # sessions where tetrode numbers got messed up by plugging\
preamplifiers wrong
-> acq.Sessions

-----



wrongtetmap_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef WrongTetMap < dj.Relvar

	properties(Constant)
		table = dj.Table('sess.WrongTetMap')
	end

	methods
		function self = WrongTetMap(varargin)
			self.restrict(varargin{:})
		end
	end
end
