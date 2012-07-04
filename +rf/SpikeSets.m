%{
rf.SpikeSets (computed) # my newest table
-> rf.Phys
-> rf.SpikeWinParams
-----

%}

classdef SpikeSets < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.SpikeSets')
    end
    properties
        popRel = rf.Phys * rf.SpikeWinParams  % !!! update the populate relation
    end
    
    methods
        function self = SpikeSets(varargin)
            self.restrict(varargin)
        end
        
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            makeTuples(rf.TrialSpikes,key)
        end
        
        function plotMaps(self,varargin)
            
            figure
            set(gcf,'Position',[296,183,646,478])
            
            key = fetch(self);
            md = fetch(rf.Map2d(key));
            
            allLags = [md.lag];
            lags = unique(allLags);
            all_mapTypes = [md.map_type_num];
            map_type_num = unique(all_mapTypes);
            map_type_str = fetchn(rf.MapTypes(sprintf('map_type_num in %s',...
            util.array2csvStr(map_type_num))),'map_type');
            nMapTypes = length(map_type_num);
            nLags = length(lags);
            c = 0;
            for i = 1:nMapTypes
                for j = 1:nLags
                    c = c + 1;
                    subplot(nMapTypes,nLags,c)
                    plot(rf.Map2d(key) & sprintf('map_type_num = %u and lag = %u',map_type_num(i),...
                        lags(j)));
                    cylabel(map_type_str{i},j==1);
                    ctitle(sprintf('%u ms',lags(j)),i==1);
                end
            end
        end
    end
end
