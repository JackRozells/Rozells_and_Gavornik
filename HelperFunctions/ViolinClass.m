classdef ViolinClass < handle
    % Violin creates violin plots for some data
    %   A violin plot is an easy to read substitute for a box plot
    %   that replaces the box shape with a kernel density estimate of
    %   the data, and optionally overlays the data points itself.
    %
    %   Additional constructor parameters include the width of the
    %   plot, the bandwidth of the kernel density estimation, and the
    %   X-axis position of the violin plot.
    %
    %   See for more information on Violin Plots:
    %   J. L. Hintze and R. D. Nelson, "Violin plots: a box
    %   plot-density trace synergism," The American Statistician, vol.
    %   52, no. 2, pp. 181-184, 1998.
    %
    % Violin Properties:
    %    ViolinColor - Fill color of the violin area and data points.
    %                  Defaults to the next default color cycle.
    %    ViolinAlpha - Transparency of the ciolin area and data points.
    %                  Defaults to 0.3.
    %    EdgeColor   - Color of the violin area outline.
    %                  Defaults to [0.5 0.5 0.5]
    %    BoxColor    - Color of the box, whiskers, and the outlines of
    %                  the median point and the notch indicators.
    %                  Defaults to [0.5 0.5 0.5]
    %    MedianColor - Fill color of the median and notch indicators.
    %                  Defaults to [1 1 1]
    %    ShowData    - Whether to show data points.
    %                  Defaults to true
    %    ShowNotches - Whether to show notch indicators.
    %                  Defaults to false
    %    ShowMean    - Whether to show mean indicator.
    %                  Defaults to false
    %
    % Violin Children:
    %    ScatterPlot - <a href="matlab:help('scatter')">scatter</a> plot of the data points
    %    ViolinPlot  - <a href="matlab:help('fill')">fill</a> plot of the kernel density estimate
    %    BoxPlot     - <a href="matlab:help('fill')">fill</a> plot of the box between the quartiles
    %    WhiskerPlot - line <a href="matlab:help('plot')">plot</a> between the whisker ends
    %    MedianPlot  - <a href="matlab:help('scatter')">scatter</a> plot of the median (one point)
    %    NotchPlots  - <a href="matlab:help('scatter')">scatter</a> plots for the notch indicators
    %    MeanPlot    - line <a href="matlab:help('plot')">plot</a> at mean value
    %
    %   Modifed from original to include additional elements and add the ability to turn some elements on/off
    %   QuartilePlots % horizontal line plots of quartile markers
    %   ShowQuartiles % true/false = on/off
    %   ShowBox
    %   ShowWhiskers
    %   ShowMedian
    %   Set the following to extend the range over which violin is plotted
    %   ClipRange % default to true, otherwise show full range of density estimate

    % Copyright (c) 2016, Bastian Bechtold
    % This code is released under the terms of the BSD 3-clause license
    %
    % Modified from original code in 2021 by Jeff Gavornik to produce
    % interactive objects and include additional customization options
    % Would be nice to modify so that the bandwidth is dynamic but right
    % now it sticks at the parameter passed to the constructor

    properties (Hidden)
        ScatterPlot % scatter plot of the data points
        ViolinPlot  % fill plot of the kernel density estimate
        ViolinPlotClipped % violin plot clipped at actual data range
        BoxPlot     % fill plot of the box between the quartiles
        WhiskerPlot % line plot between the whisker ends
        MedianPlot  % scatter plot of the median (one point)
        NotchPlots  % scatter plots for the notch indicators
        MeanPlot    % line plot of the mean (horizontal line)
        QuartilePlots % horizontal line plots of quartile markers
        RangeMarkers % horizontal line plots of min,max data when clipping is off
    end

    properties (SetAccess=immutable)
        OptimalBandwidth % Optimal bandwidth for data returned by ksdensity
    end

    properties
        Bandwidth % bandwidth used to calculate the plot
        PlotHandles % Handles to all of the plot objects
    end

    properties (Dependent)
        
        ViolinColor % fill color of the violin area and data points
        ViolinAlpha % transparency of the violin area and data points
        EdgeColor   % color of the violin area outline
        BoxColor    % color of box, whiskers, and median/notch edges
        BoxWidth    % width of box between the quartiles in axis space (default 10% of Violin plot width, 0.03)
        MedianColor % fill color of median and notches
        ShowData    % whether to show data points
        ShowNotches % whether to show notch indicators
        ShowMean    % whether to show mean indicator
        ShowQuartiles
        ShowBox
        ShowWhiskers
        ShowMedian
        ShowRange
        ClipRange
    end

    methods
        function obj = ViolinClass(data, pos, varargin)
            %Violin plots a violin plot of some data at pos
            %   VIOLIN(DATA, POS) plots a violin at x-position POS for
            %   a vector of DATA points.
            %
            %   VIOLIN(..., 'PARAM1', val1, 'PARAM2', val2, ...)
            %   specifies optional name/value pairs:
            %     'Width'        Width of the violin in axis space.
            %                    Defaults to 0.3
            %     'Bandwidth'    Bandwidth of the kernel density
            %                    estimate. Should be between 10% and
            %                    40% of the data range.
            %     'ViolinColor'  Fill color of the violin area and
            %                    data points. Defaults to the next
            %                    default color cycle.
            %     'ViolinAlpha'  Transparency of the violin area and
            %                    data points. Defaults to 0.3.
            %     'EdgeColor'    Color of the violin area outline.
            %                    Defaults to [0.5 0.5 0.5]
            %     'BoxColor'     Color of the box, whiskers, and the
            %                    outlines of the median point and the
            %                    notch indicators. Defaults to
            %                    [0.5 0.5 0.5]
            %     'MedianColor'  Fill color of the median and notch
            %                    indicators. Defaults to [1 1 1]
            %     'ShowData'     Whether to show data points.
            %                    Defaults to true
            %     'ShowNotches'  Whether to show notch indicators.
            %                    Defaults to false
            %     'ShowMean'     Whether to show mean indicator.
            %                    Defaults to false

            args = obj.checkInputs(data, pos, varargin{:});
            data = data(not(isnan(data)));
            if numel(data) == 1
                obj.MedianPlot = scatter(pos, data, 'filled');
                obj.MedianColor = args.MedianColor;
                obj.MedianPlot.MarkerEdgeColor = args.EdgeColor;
                return
            end

            hold('on');

            % calculate kernel density estimation for the violin
            if isempty(data)
                return
            end
            
            [density, value, bw] = ksdensity(data, 'bandwidth', args.Bandwidth);
            if isempty(args.Bandwidth)
                obj.OptimalBandwidth = bw;
            else
                [~,~,obj.OptimalBandwidth] = ksdensity(data, 'bandwidth', []);
            end
            obj.Bandwidth = bw;
            
            % all data is identical
            if min(data) == max(data)
                density = 1;
            end
            width = args.Width/max(density);
            
            % plot the violin
            obj.ViolinPlot =  ... % plot color will be overwritten later
                fill([pos+density*width pos-density(end:-1:1)*width], ...
                [value value(end:-1:1)], [1 1 1]);
            
            % Clip density to actual data range and plot another violin
            density = density(value >= min(data) & value <= max(data));
            value = value(value >= min(data) & value <= max(data));
            value(1) = min(data);
            value(end) = max(data);
            obj.ViolinPlotClipped = ...
                fill([pos+density*width pos-density(end:-1:1)*width], ...
                [value value(end:-1:1)], [1 1 1]);
            obj.ClipRange = args.ClipRange; % this will set visibility correctly
            
            % plot the data points within the violin area
            if length(density) > 1
                jitterstrength = interp1(value, density*width, data);
            else % all data is identical:
                jitterstrength = density*width;
            end
            jitter = 2*(rand(size(data))-0.5);
            obj.ScatterPlot = ...
                scatter(pos + jitter.*jitterstrength, data, 'filled');

            % plot the mini-boxplot within the violin
            quartiles = quantile(data, [0.25, 0.5, 0.75]);         
            obj.BoxPlot = ... % plot color will be overwritten later
                fill(pos+[-1,1,1,-1]*args.BoxWidth, ...
                     [quartiles(1) quartiles(1) quartiles(3) quartiles(3)], ...
                     [1 1 1]);
                 
            % plot the data mean
            meanValue = mean(data);
            if length(density) > 1
                meanDensityWidth = interp1(value, density, meanValue)*width;
            else % all data is identical:
                meanDensityWidth = density*width;
            end
            if meanDensityWidth<args.BoxWidth/2
                meanDensityWidth=args.BoxWidth/2;
            end
            obj.MeanPlot = plot(pos+[-1,1].*meanDensityWidth, ...
                                [meanValue, meanValue],'k');
            obj.MeanPlot.LineWidth = 1;
                 
            IQR = quartiles(3) - quartiles(1);
            lowhisker = quartiles(1) - 1.5*IQR;
            lowhisker = max(lowhisker, min(data(data > lowhisker)));
            hiwhisker = quartiles(3) + 1.5*IQR;
            hiwhisker = min(hiwhisker, max(data(data < hiwhisker)));
            if ~isempty(lowhisker) && ~isempty(hiwhisker)
                obj.WhiskerPlot = plot([pos pos], [lowhisker hiwhisker]);
            end
            obj.MedianPlot = scatter(pos, quartiles(2), [], [1 1 1], 'filled');

            % JG - mark quartiles with horizontal lines
            q1Width = interp1(value, density, quartiles(1))*width;
            q2Width = interp1(value, density, quartiles(2))*width;
            q3Width = interp1(value, density, quartiles(3))*width;
            obj.QuartilePlots = plot(pos+[-1,1].*q1Width,quartiles(1)*[1 1],'-');
            obj.QuartilePlots(2) = plot(pos+[-1,1].*q2Width,quartiles(2)*[1 1],'--');
            obj.QuartilePlots(3) = plot(pos+[-1,1].*q3Width,quartiles(3)*[1 1],'-');  
            
            % JG - mark max data ranges if clipping is off
            if ~obj.ClipRange
                maxWidth = interp1(value, density, max(data))*width;
                minWidth = interp1(value, density, min(data))*width;
                obj.RangeMarkers = plot(pos+[-1,1].*maxWidth,max(data)*[1 1],':');
                obj.RangeMarkers(2) = plot(pos+[-1,1].*minWidth,min(data)*[1 1],':');
            end
            
            obj.NotchPlots = ...
                 scatter(pos, quartiles(2)-1.57*IQR/sqrt(length(data)), ...
                         [], [1 1 1], 'filled', '^');
            obj.NotchPlots(2) = ...
                 scatter(pos, quartiles(2)+1.57*IQR/sqrt(length(data)), ...
                         [], [1 1 1], 'filled', 'v');

            obj.EdgeColor = args.EdgeColor;
            obj.BoxColor = args.BoxColor;
            obj.BoxWidth = args.BoxWidth;
            obj.MedianColor = args.MedianColor;
            if not(isempty(args.ViolinColor))
                obj.ViolinColor = args.ViolinColor;
            else
                obj.ViolinColor = obj.ScatterPlot.CData;
            end
            obj.ViolinAlpha = args.ViolinAlpha;
            obj.ShowData = args.ShowData;
            obj.ShowNotches = args.ShowNotches;
            obj.ShowMean = args.ShowMean;
            obj.ShowBox = args.ShowBox;
            obj.ShowWhiskers = args.ShowWhiskers;
            obj.ShowMedian = args.ShowMedian;
            obj.ShowQuartiles = args.ShowQuartiles;
            obj.ShowRange = args.ShowRange;

        end

        function set.EdgeColor(obj, color)
            if ~isempty(obj.ViolinPlot)
                obj.ViolinPlot.EdgeColor = color;
            end
        end

        function color = get.EdgeColor(obj)
            if ~isempty(obj.ViolinPlot)
                color = obj.ViolinPlot.EdgeColor;
            end
        end

        function set.MedianColor(obj, color)
            obj.MedianPlot.MarkerFaceColor = color;
            if ~isempty(obj.NotchPlots)
                obj.NotchPlots(1).MarkerFaceColor = color;
                obj.NotchPlots(2).MarkerFaceColor = color;
            end
        end

        function color = get.MedianColor(obj)
            color = obj.MedianPlot.MarkerFaceColor;
        end

        function set.BoxColor(obj, color)
            if ~isempty(obj.BoxPlot)
                obj.BoxPlot.FaceColor = color;
                obj.BoxPlot.EdgeColor = color;
                obj.WhiskerPlot.Color = color;
                obj.MedianPlot.MarkerEdgeColor = color;
                obj.NotchPlots(1).MarkerFaceColor = color;
                obj.NotchPlots(2).MarkerFaceColor = color;
            end
        end

        function color = get.BoxColor(obj)
            if ~isempty(obj.BoxPlot)
                color = obj.BoxPlot.FaceColor;
            end
        end
        
        function set.BoxWidth(obj,width)
            if ~isempty(obj.BoxPlot)
                pos=mean(obj.BoxPlot.XData);
                obj.BoxPlot.XData=pos+[-1,1,1,-1]*width;
            end
        end
        
        function width = get.BoxWidth(obj)
            width=max(obj.BoxPlot.XData)-min(obj.BoxPlot.XData);
        end

        function set.ViolinColor(obj, color)
            obj.ViolinPlot.FaceColor = color;
            obj.ViolinPlotClipped.FaceColor = color;
            obj.ScatterPlot.MarkerFaceColor = color*0.75;
            % obj.MeanPlot.Color = color;
            obj.QuartilePlots(1).Color = color*0.75;
            obj.QuartilePlots(2).Color = color*0.75;
            obj.QuartilePlots(3).Color = color*0.75;
            if ~obj.ClipRange
                obj.RangeMarkers(1).Color = color*0.75;
                obj.RangeMarkers(2).Color = color*0.75;
            end
        end

        function color = get.ViolinColor(obj)
            color = obj.ViolinPlot.FaceColor;
        end

        function set.ViolinAlpha(obj, alpha)
            obj.ScatterPlot.MarkerFaceAlpha = alpha;
            obj.ViolinPlot.FaceAlpha = alpha;
            obj.ViolinPlotClipped.FaceAlpha = alpha;
        end

        function alpha = get.ViolinAlpha(obj)
            alpha = obj.ViolinPlot.FaceAlpha;
        end

        function set.ShowData(obj, yesno)
            if yesno
                obj.ScatterPlot.Visible = 'on';
            else
                obj.ScatterPlot.Visible = 'off';
            end
        end

        function yesno = get.ShowData(obj)
            if ~isempty(obj.ScatterPlot)
                yesno = strcmp(obj.ScatterPlot.Visible, 'on');
            end
        end

        function set.ShowNotches(obj, yesno)
            if ~isempty(obj.NotchPlots)
                if yesno
                    obj.NotchPlots(1).Visible = 'on';
                    obj.NotchPlots(2).Visible = 'on';
                else
                    obj.NotchPlots(1).Visible = 'off';
                    obj.NotchPlots(2).Visible = 'off';
                end
            end
        end

        function yesno = get.ShowNotches(obj)
            if ~isempty(obj.NotchPlots)
                yesno = strcmp(obj.NotchPlots(1).Visible, 'on');
            end
        end

        function set.ShowMean(obj, yesno)
            if ~isempty(obj.MeanPlot)
                if yesno
                    obj.MeanPlot.Visible = 'on';
                else
                    obj.MeanPlot.Visible = 'off';
                end
            end
        end

        function yesno = get.ShowMean(obj)
            if ~isempty(obj.MeanPlot)
                yesno = strcmp(obj.MeanPlot.Visible, 'on');
            end
        end
        
        function set.ShowQuartiles(obj, yesno)
            if ~isempty(obj.QuartilePlots)
                if yesno
                    val = 'on';
                else
                    val = 'off';
                end
                obj.QuartilePlots(1).Visible = val;
                obj.QuartilePlots(2).Visible = val;
                obj.QuartilePlots(3).Visible = val;
            end
        end

        function yesno = get.ShowQuartiles(obj)
            if ~isempty(obj.QuartilePlots(1))
                yesno = strcmp(obj.QuartilePlots(1).Visible, 'on');
            end
        end
        
        function set.ShowRange(obj,yesno)
            if ~isempty(obj.RangeMarkers)
                if yesno
                    val = 'on';
                else
                    val = 'off';
                end
                obj.RangeMarkers(1).Visible = val;
                obj.RangeMarkers(2).Visible = val;
            end
        end

        function yesno = get.ShowRange(obj)
            if ~isempty(obj.RangeMarkers(1))
                yesno = strcmp(obj.RangeMarkers(1).Visible, 'on');
            end
        end
        
        function set.ShowBox(obj, yesno)
            if ~isempty(obj.BoxPlot)
                if yesno
                    obj.BoxPlot.Visible = 'on';
                else
                    obj.BoxPlot.Visible = 'off';
                end
            end
        end

        function yesno = get.ShowBox(obj)
            if ~isempty(obj.BoxPlot)
                yesno = strcmp(obj.BoxPlot.Visible, 'on');
            end
        end
                
        function set.ShowWhiskers(obj, yesno)
            if ~isempty(obj.WhiskerPlot)
                if yesno
                    obj.WhiskerPlot.Visible = 'on';
                else
                    obj.WhiskerPlot.Visible = 'off';
                end
            end
        end
        
        function yesno = get.ShowWhiskers(obj)
            if ~isempty(obj.WhiskerPlot)
                yesno = strcmp(obj.WhiskerPlot.Visible, 'on');
            end
        end
        
        function set.ShowMedian(obj,yesno)
            if ~isempty(obj.MedianPlot)
                if yesno
                    obj.MedianPlot.Visible = 'on';
                else
                    obj.MedianPlot.Visible = 'off';
                end
            end
        end

        function yesno = get.ShowMedian(obj)
            if ~isempty(obj.MedianPlot)
                yesno = strcmp(obj.MedianPlot.Visible, 'on');
            end
        end
        
        function set.ClipRange(obj,yesno)
            if ~isempty(obj.ViolinPlotClipped)
                if yesno
                    obj.ViolinPlotClipped.Visible = 'on';
                    obj.ViolinPlot.Visible = 'off';
                else
                    obj.ViolinPlotClipped.Visible = 'off';
                    obj.ViolinPlot.Visible = 'on';
                end
            end
        end

        function clipRange = get.ClipRange(obj)
            clipRange = obj.ViolinPlot.Visible == "off";
        end


        function handles = get.PlotHandles(obj)
            % Return structure with all of the plot handles
            handles.ScatterPlot = obj.ScatterPlot;
            handles.ViolinPlot = obj.ViolinPlot;
            handles.ViolinPlotClipped = obj.ViolinPlotClipped;
            handles.BoxPlot = obj.BoxPlot;
            handles.WhiskerPlot = obj.WhiskerPlot;
            handles.MedianPlot = obj.MedianPlot;
            handles.NotchPlots = obj.NotchPlots;
            handles.MeanPlot = obj.MeanPlot;
            handles.QuartilePlots = obj.QuartilePlots;
            handles.RangeMarkers = obj.RangeMarkers;
        end
    end

    methods (Access=private)
        function results = checkInputs(obj, data, pos, varargin) %#ok<INUSL>
            isscalarnumber = @(x) (isnumeric(x) & isscalar(x));
            p = inputParser();
            p.addRequired('Data', @isnumeric);
            p.addRequired('Pos', isscalarnumber);
            p.addParameter('Width', 0.3, isscalarnumber);
            p.addParameter('Bandwidth', [], isscalarnumber);
            iscolor = @(x) (isnumeric(x) & length(x) == 3);
            p.addParameter('ViolinColor', [], iscolor);
            p.addParameter('BoxColor', [0.5 0.5 0.5], iscolor);
            p.addParameter('BoxWidth', 0.01, isscalarnumber);
            p.addParameter('EdgeColor', [0.5 0.5 0.5], iscolor);
            p.addParameter('MedianColor', [1 1 1], iscolor);
            p.addParameter('ViolinAlpha', 0.3, isscalarnumber);
            isscalarlogical = @(x) (islogical(x) & isscalar(x));
            p.addParameter('ShowData', true, isscalarlogical);
            p.addParameter('ShowNotches', false, isscalarlogical);
            p.addParameter('ShowMean', false, isscalarlogical);
            p.addParameter('ClipRange',true,isscalarlogical);
            p.addParameter('ShowBox', true, isscalarlogical);
            p.addParameter('ShowWhiskers', true, isscalarlogical);
            p.addParameter('ShowMedian', true, isscalarlogical);
            p.addParameter('ShowQuartiles', false, isscalarlogical);
            p.addParameter('ShowRange', true, isscalarlogical);
            p.parse(data, pos, varargin{:});
            results = p.Results;
        end
    end
end