%{
fle.StimCenProxCond (computed) # my newest table
-> fle.TrialGroup
cond_idx : smallint unsigned # cond index
-----
arr_rf_in = -1: tinyint # -1 invalid arrangement, arrangement where stim was in rf
flash_in_rf = 0: tinyint # was flash in rf
mov_in_rf = 0: tinyint # was mov in rf
flash_shown = 0: tinyint # blah
mov_shown = 0: tinyint # blah
direction = -1: tinyint # movement direction
bar_color_r : tinyint unsigned # red
bar_color_g : tinyint unsigned # green
bar_color_b : tinyint unsigned # blue
is_init=0   : boolean # is flash initiated condtion
is_stop=0   : boolean # is flash terminated condtion
dx = Null : smallint unsigned # change in pixels per frame
%}

classdef StimCenProxCond < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('fle.StimCenProxCond')
        popRel = fle.TrialGroup;  % !!! update the populate relation
    end
    
    methods
        function self = StimCenProxCond(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            
            % For a flash or moving bar condition, find the arrangement where the given stimulus was
            % close to the stim center
            
            cond = fetch(fle.StimCond(key),'*');
            nCond = length(cond);
            OFFSET_LIM = 20; % Pixels within stim center to consider that the stim was in rf
            
            % Is it single or combined?
            cp = fetch(fle.StimConstants(key),'combined');
            
            if ~cp.combined
                flash_in_rf = [cond.is_flash]==1;
                mov_in_rf = [cond.is_moving]==1;
                flash_shown = flash_in_rf;
                mov_shown = mov_in_rf;
                for iCond = 1:nCond
                    tuple = key;
                    tuple.cond_idx = cond(iCond).cond_idx;
                    tuple.flash_in_rf = flash_in_rf(iCond);
                    tuple.mov_in_rf = mov_in_rf(iCond);
                    tuple.flash_shown = flash_shown(iCond);
                    tuple.mov_shown = mov_shown(iCond);
                    tuple.arr_rf_in = cond(iCond).arrangement;
                    tuple.direction = cond(iCond).direction;
                    tuple.dx = cond(iCond).dx;
                    tuple.bar_color_r = cond(iCond).bar_color_r;
                    tuple.bar_color_g = cond(iCond).bar_color_g;
                    tuple.bar_color_b = cond(iCond).bar_color_b;
                    tuple.is_init = cond(iCond).is_init;
                    tuple.is_stop = cond(iCond).is_stop;
                    %!!! compute missing fields for key here
                    self.insert(tuple)
                end
            else
                stimCenY = fetch1(fle.StimConstants(key),'stim_center_y');
                for iCond = 1:nCond
                    tuple = key;
                    % Find the arrangement for the given condition and find the other
                    % arrangement and compare both
                    
                    ct = cond(iCond);
                    
                    % Look for the other arrangement only for flash or moving bar only condition
                    flashOnly = ct.is_flash && ~ct.is_moving;
                    movOnly = ~ct.is_flash && ct.is_moving;
                    
                    if flashOnly || movOnly
                        
                        if flashOnly
                            param = 'flash_centers';
                            barType = 'flash';
                        else
                            param = 'bar_centers';
                            barType = 'mov';
                        end
                        bd = fetch(fle.SubTrials(key,sprintf('cond_idx=%u',ct.cond_idx)),param,1);
                        xy = bd.(param){:};
                        y = xy(2,1);
                        
                        % Check if the current stim condition was closer to the stim center
                        if abs(y - stimCenY) < OFFSET_LIM
                            tuple.arr_rf_in = ct.arrangement;
                            tuple.([barType '_in_rf']) = 1;
                        end
                        
                        tuple.([barType '_shown']) = 1;
                        
                    elseif ct.is_flash && ct.is_moving
                        
                        tuple.flash_shown = 1;
                        tuple.mov_shown = 1;
                        tuple.arr_rf_in = ct.arrangement;
                        
                        bd = fetch(fle.SubTrials(key,sprintf('cond_idx=%u',ct.cond_idx)),'flash_centers',1);
                        xy = bd.flash_centers{:};
                        flash_y = xy(2,1);
                        bd = fetch(fle.SubTrials(key,sprintf('cond_idx=%u',ct.cond_idx)),'bar_centers',1);
                        xy = bd.bar_centers{:};
                        mov_y = xy(2,1);
                        [~,closer] = min(abs([flash_y mov_y]-stimCenY));
                        if closer==1
                            tuple.flash_in_rf = 1;
                        elseif closer==2
                            tuple.mov_in_rf = 1;
                        end
                    end
                    tuple.cond_idx = ct.cond_idx;
                    tuple.direction = ct.direction;
                    tuple.dx = ct.dx;
                    tuple.bar_color_r = cond(iCond).bar_color_r;
                    tuple.bar_color_g = cond(iCond).bar_color_g;
                    tuple.bar_color_b = cond(iCond).bar_color_b;
                    tuple.is_init = cond(iCond).is_init;
                    tuple.is_stop = cond(iCond).is_stop;
                    self.insert(tuple)
                end
            end
        end
    end
end

