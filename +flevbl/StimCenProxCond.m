%{
flevbl.StimCenProxCond (computed) # my newest table
-> flevbl.TrialGroup
cond_idx : smallint unsigned # cond index
-----
arr_rf_in = -1: tinyint # -1 invalid arrangement, arrangement where stim was in rf
flash_in_rf = 0: tinyint # was flash in rf
mov_in_rf = 0: tinyint # was mov in rf
flash_shown = 0: tinyint # blah
mov_shown = 0: tinyint # blah
direction = -1: tinyint # movement direction
dx = Null : smallint unsigned # change in pixels per frame
%}

classdef StimCenProxCond < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('flevbl.StimCenProxCond')
    end
    properties
        popRel = flevbl.TrialGroup;  % !!! update the populate relation
    end
    
    methods
        function self = StimCenProxCond(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            
            % For a flash or moving bar condition, find the arrangement where the given stimulus was
            % close to the stim center
            
            
            cond = fetch(flevbl.StimCond(key),'*');
            nCond = length(cond);
            OFFSET_LIM = 20; % Pixels within stim center to consider that the stim was in rf
            
            % Is it single or combined?
            cp = fetch(flevbl.StimConstants(key),'combined');
            tuples = repmat(key,1,nCond);
            
            if ~cp.combined
                flash_in_rf = [cond.is_flash]==1;
                mov_in_rf = [cond.is_moving]==1;
                flash_shown = flash_in_rf;
                mov_shown = mov_in_rf;
                for iCond = 1:nCond
                    tuples(iCond).cond_idx = cond(iCond).cond_idx;
                    tuples(iCond).flash_in_rf = flash_in_rf(iCond);
                    tuples(iCond).mov_in_rf = mov_in_rf(iCond);
                    tuples(iCond).flash_shown = flash_shown(iCond);
                    tuples(iCond).mov_shown = mov_shown(iCond);
                    tuples(iCond).arr_rf_in = cond(iCond).arrangement;
                    tuples(iCond).direction = cond(iCond).direction;
                    tuples(iCond).dx = cond(iCond).dx;
                end
            else
                
                stimCenY = fetch1(flevbl.StimConstants(key),'stim_center_y');
                for iCond = 1:nCond
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
                        bd = fetch(flevbl.SubTrials(key,sprintf('cond_idx=%u',ct.cond_idx)),param,1);
                        xy = bd.(param){:};
                        y = xy(2,1);
                                               
                        % Check if the current stim condition was closer to the stim center
                        if abs(y - stimCenY) < OFFSET_LIM
                            tuples(iCond).arr_rf_in = ct.arrangement;
                            tuples(iCond).([barType '_in_rf']) = 1;
                        end
                        
                        tuples(iCond).([barType '_shown']) = 1;
                        
                    elseif ct.is_flash && ct.is_moving
                        
                        tuples(iCond).flash_shown = 1;
                        tuples(iCond).mov_shown = 1;
                        tuples(iCond).arr_rf_in = ct.arrangement;
                        
                        bd = fetch(flevbl.SubTrials(key,sprintf('cond_idx=%u',ct.cond_idx)),'flash_centers',1);
                        xy = bd.flash_centers{:};
                        flash_y = xy(2,1);
                        bd = fetch(flevbl.SubTrials(key,sprintf('cond_idx=%u',ct.cond_idx)),'bar_centers',1);
                        xy = bd.bar_centers{:};
                        mov_y = xy(2,1);
                        [~,closer] = min(abs([flash_y mov_y]-stimCenY));
                        if closer==1
                            tuples(iCond).flash_in_rf = 1;
                        elseif closer==2
                            tuples(iCond).mov_in_rf = 1;
                        end
                    end
                    tuples(iCond).cond_idx = ct.cond_idx;
                    tuples(iCond).direction = ct.direction;
                    tuples(iCond).dx = ct.dx;
                end
            end
            %!!! compute missing fields for key here
            self.insert(tuples)
        end
    end
end
