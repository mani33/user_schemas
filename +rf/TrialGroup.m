% rf.TrialGroup - Subset of DotMappingExperiment sessions

%{
rf.TrialGroup (computed) # my newest table
-> stimulation.StimTrialGroup
-----

%}

classdef TrialGroup < dj.Relvar & dj.AutoPopulate
    
    properties(Constant)
        table = dj.Table('rf.TrialGroup')
        popRel = (stimulation.StimTrialGroup-acq.StimulationIgnore) & ephys.SpikeSet &...
            acq.Stimulation('exp_type =''DotMappingExperiment'' and correct_trials >= 100')...
            - acq.SessionsIgnore;
    end
    
    methods
        function self = TrialGroup(varargin)
            self.restrict(varargin)
        end
    end
    methods(Access = protected)
        function makeTuples(self, key)
            %!!! compute missing fields for key here
            self.insert(key)
            % Populate subtables
%             makeTuples(rf.Phys,key)
            makeTuples(rf.StimConstants,key)
            makeTuples(rf.Trials,key)
        end
    end
    methods
        function varargout = plotMapForTetArray(self,xLim,yLim)
            
            if nargin < 2
                xLim = [];
                yLim = [];
            elseif nargin < 3
                yLim = [];
            end
            key = fetch(self * acq.Subjects * acq.Sessions,'*');
            
            tetArrayLayout = getTetrodeArrayLayout(key.subject_name,1);
            [nRows nCols] = size(tetArrayLayout);
            c = 0;
            figure;
            font_size = 6;
            set(gcf,'Position',[221,49,772,668])
            dot_size = fetch1(rf.StimConstants(key),'dot_size');
            dnx = fetch1(rf.StimConstants(key),'dot_num_x');
            dny = fetch1(rf.StimConstants(key),'dot_num_y');
            % Plot
            for iRow = 1:nRows
                for iCol = 1:nCols
                    c = c + 1;
                    tet = tetArrayLayout{iRow,iCol};
                    if ischar(tet) && ismember(tet,{'R1','R2','R3','R4'}) % ref
                        subplot(nRows,nCols,c);
                        imagesc(cat(3,0*ones(dny,dnx),0*ones(dny,dnx),0.8*ones(dny,dnx)));
                        title(tet,'FontSize', font_size,'Color',[1 0 0]);
                        axis image;
                        set(gca,'FontSize', font_size,'XTickLabel',[],'YTickLabel',[])
                        if ~isempty(xLim)
                            xlim(xLim);
                        end
                        if ~isempty(yLim)
                            ylim(yLim);
                        end
                    elseif ~isnan(tet) % tetrodes
                        titStr = sprintf('TT %0.0d',tet);
                        rv = rf.MapAvg(sprintf('map_type_num=3 and subject_id=%u',key.subject_id)) & ...
                            key & ephys.Spikes(sprintf('electrode_num = %u',tet));
                        subplot(nRows,nCols,c);
                        if count(rv) > 0  % live electrodes
                            plot(rv);
                            set(gca,'FontSize', font_size);
                            title(titStr,'FontSize', font_size);
                            
                        else % dead/non-existent electrodes
                            imagesc(cat(3,0*ones(dny,dnx),0*ones(dny,dnx),0.8*ones(dny,dnx)));
                            title(titStr,'FontSize', font_size);
                            axis image;
                            set(gca,'FontSize', font_size,'XTickLabel',[],'YTickLabel',[])
                        end
                        if ~isempty(xLim)
                            xlim(xLim);
                        end
                        if ~isempty(yLim)
                            ylim(yLim);
                        end
                    end
                end
            end
            dotSizeDeg = dot_size/fetch1(stim.PixPerDeg(self),'pix_per_deg');
            ms_suptitle([key.subject_name '  ' key.session_datetime sprintf('   dotSize: %0.2f deg',dotSizeDeg)]);
            if nargout
                varargout{1} = key.session_datetime(1:10);
            end
        end
        
        function plotRfOutlines(self,varargin)
            % Plot the receptive field outlines for all the multiunits from the given
            % session.
            eKeys = fetch(rf.FitAvg(self,'map_type_num=3'));
            for key = eKeys'
                [ox oy] = getOutline(rf.FitAvg(key));
                plot(ox,oy,'k')
                hold on
            end
            
            set(gca,'YDir','Reverse','Xlim',[-0.5 4],'Ylim',[-0.5 2.5])
            plot([0 0],ylim,'r')
            plot(xlim,[0 0],'r')
            axis equal
            set(gca,'Xlim',[-0.5 4],'Ylim',[-0.5 2.5])
        end
        function plotRfCenters(self,varargin)
            % Plot the receptive field centers for all the multiunits from the given
            % session.
            args = struct;
            args = parseVarArgs(args,varargin{:});
            argList = struct2argList(args);
            
            eKeys = fetch(rf.FitAvg(self,'map_type_num=3'));
            for key = eKeys'
                [cx cy] = fetchn(rf.FitAvg(key),'cen_x','cen_y');
                plot(cx,cy,'k.','MarkerSize',14,argList{:})
                hold on
            end
            
            set(gca,'YDir','Reverse','Xlim',[-0.5 4],'Ylim',[-0.5 2.5])
            plot([0 0],ylim,'r')
            plot(xlim,[0 0],'r')
            axis equal
            set(gca,'Xlim',[-0.5 4],'Ylim',[-0.5 2.5])
            
        end
    end
end