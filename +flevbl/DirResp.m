% flevbl.DirResp - my newest table
% Mean firing rate for the two directions of motion

%{
flevbl.DirResp (computed) # my newest table
-> flevbl.SpikeSets
-> flevbl.DirRespParams
-> flevbl.DxVals
-----
mean_fr_dir0 = Null: double # mean firing rate for direction = 0
mean_fr_dir1 = Null: double # mean firing rate for direction = 1
%}

classdef DirResp < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.DirResp')
    end
    
    properties
        popRel = flevbl.SpikeSets * flevbl.DirRespParams * flevbl.DxVals % !!! update the populate relation
    end
    
    methods
        function self = DirResp(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self,key)
            % Is the neuron directionally selective?
            % Compute direction selectivity for each speed and average them
            
            [key.mean_fr_dir0 key.mean_fr_dir1] = getDirSelResp(flevbl.SpikeSets(key),...
                key.dx,key.resp_win_start, key.resp_win_end);
            self.insert(key)
        end
    end
end
