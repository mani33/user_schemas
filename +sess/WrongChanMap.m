%{
sess.WrongChanMap (manual) # sessions where channel mapping for tetrodes were messed up\
by plugging the preamplifiers wrong
-> acq.Sessions

-----



wrongchanmap_ts = CURRENT_TIMESTAMP: timestamp           # automatic timestamp. Do not edit
%}

classdef WrongChanMap < dj.Relvar

	properties(Constant)
		table = dj.Table('sess.WrongChanMap')
	end

	methods
		function self = WrongChanMap(varargin)
			self.restrict(varargin{:})
		end
	end
end
