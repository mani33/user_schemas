%{
rf.MapAvg (computed) # my newest table
-> rf.MapSets
-> rf.MapTypes
-> rf.MapAvgParams
-----
map: longblob # average map
%}

classdef MapAvg < dj.Relvar
	properties(Constant)
		table = dj.Table('rf.MapAvg')
	end
	
	methods
		function self = MapAvg(varargin)
			self.restrict(varargin)
		end

        function makeTuples(self, key)
            keys = fetch(rf.MapSets(key) * rf.MapAvgParams * rf.MapTypes);
            for key = keys'
                qs = sprintf('lag >= %u and lag <= %u and map_type_num = %u',...
                    key.min_lag,key.max_lag,key.map_type_num);
                maps = fetchn(rf.Map(key,qs),'map');
                key.map = mean(cat(3,maps{:}),3);
                self.insert(key)
            end
        end
        
         function varargout = plot(self,varargin)
            
            arg.smooth = 5;
            arg.axis = [];
            arg.xylim_deg = []; % [xlim(1) xlim(2) ylim(1) ylim(2)]
            arg.bkgdCol = [0 0.25 1];
            arg.units = 'deg'; % deg or pix
            arg = parseVarArgs(arg,varargin{:});
            
            % get all map data
            md = fetch(self,'*');
            
            % get grid
            [x y] = getGrid(rf.Map(fetch(self)),arg.units);
            
            if ~isempty(arg.axis)
                axes(arg.axis)
            end
                
            if ~isempty(arg.xylim_deg)
               ori = arg.xylim_deg([1 3]);
               width = diff(arg.xylim_deg(1:2));
               height = diff(arg.xylim_deg(3:4));
               pos = [ori width height];
               rectangle('Position',pos,'FaceColor',arg.bkgdCol)
            end
            
            hold on
            % smooth map
            w = gausswin(arg.smooth);
            w = w*w';
            w = w/sum(w(:));
            map = imfilter(md.map,w,'same');
            
            % plot map
            if isempty(find(map,1))
                map = ones(size(map));
                map = cat(3,0*map,0*map,0.8*map);
            end
            h = imagesc(x,y,map);
            hold on
            if size(map,1)==size(map,2)
                PlotTools.sqAx;
            end
            
            if isempty(arg.xylim_deg)
                axis image
            else
                axis equal
                xlim(arg.xylim_deg(1:2))
                ylim(arg.xylim_deg(3:4))
            end
            
            set(gca,'YDir','reverse','FontSize',7)
            
            if nargout
                varargout{1} = h;
            end
            
            
            % plot meridians
            plot(xlim,[0 0],'w');
            plot([0 0],ylim,'w');
        end
    end
end
