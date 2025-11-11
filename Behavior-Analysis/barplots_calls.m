%% --- USER SETTINGS ---
refTime      = datetime('21-Oct-2025 17:56:55','InputFormat','dd-MMM-yyyy HH:mm:ss'); % time = 0
startMinutes = -120;   % lower limit for x-axis
binWidth10   = 10;     % bin width for 10-min file
binWidth20   = 20;     % bin width for 20-min file

% Phase boundaries (in minutes)
pre_parturition_start = -60;
parturition_start = 0;
parturition_end   = 15;

% Define colors (matching your scatter shades)
color_baseline = [1, 1, 1];
color_pre  = [0.98, 0.31, 0.73];        % pre-parturition (light purple)
color_par  = [0.75, 0, 0.75];        % parturition (same hue)
color_post = [0.494, 0.184, 0.556];  % post-parturition (darker purple)

% --- OUTPUT FOLDER ---
outdir = fullfile('.', 'Plots');
if ~exist(outdir, 'dir'), mkdir(outdir); end

%% --- LOAD DATA ---
data10 = readtable(fullfile('..','Data','Detections_Audible','calls_10min_summary.csv'));
data20 = readtable(fullfile('..','Data','Detections_Audible','calls_20min_summary.csv'));

% Convert time columns
data10.BinCenter = datetime(data10.BinCenter,'InputFormat','dd-MMM-yyyy HH:mm:ss');
data20.BinCenter = datetime(data20.BinCenter,'InputFormat','dd-MMM-yyyy HH:mm:ss');

% Compute bin start times relative to refTime
data10.StartMin = minutes(data10.BinCenter - refTime) - binWidth10/2;
data20.StartMin = minutes(data20.BinCenter - refTime) - binWidth20/2;

% Filter window
data10 = data10(data10.StartMin >= startMinutes, :);
data20 = data20(data20.StartMin >= startMinutes, :);

% Ensure a bin starting at time 0 exists
if ~ismember(0, data10.StartMin)
    newRow = array2table(zeros(1,width(data10)),'VariableNames',data10.Properties.VariableNames);
    newRow.BinCenter = refTime + minutes(binWidth10/2);
    newRow.CallCount = 0;
    newRow.StartMin  = 0;
    data10 = [data10; newRow];
end
if ~ismember(0, data20.StartMin)
    newRow = array2table(zeros(1,width(data20)),'VariableNames',data20.Properties.VariableNames);
    newRow.BinCenter = refTime + minutes(binWidth20/2);
    newRow.CallCount = 0;
    newRow.StartMin  = 0;
    data20 = [data20; newRow];
end

% Sort after insertion
data10 = sortrows(data10,'StartMin');
data20 = sortrows(data20,'StartMin');

%% --- ASSIGN COLORS BASED ON TIME PHASES ---
barColors10 = zeros(height(data10),3);
for i = 1:height(data10)
    if data10.StartMin(i) < pre_parturition_start
        barColors10(i, :) = color_baseline;
    elseif data10.StartMin(i) < parturition_start && data10.StartMin(i) >= pre_parturition_start
        barColors10(i,:) = color_pre;
    elseif data10.StartMin(i) >= parturition_start && data10.StartMin(i) < parturition_end
        barColors10(i,:) = color_par;
    else
        barColors10(i,:) = color_post;
    end
end

barColors20 = zeros(height(data20),3);
for i = 1:height(data20)
    if data20.StartMin(i) < pre_parturition_start
        barColors20(i, :) = color_baseline;
    elseif data20.StartMin(i) < parturition_start && data20.StartMin(i) >= pre_parturition_start
        barColors20(i,:) = color_pre;
    elseif data20.StartMin(i) >= parturition_start && data20.StartMin(i) < parturition_end
        barColors20(i,:) = color_par;
    else
        barColors20(i,:) = color_post;
    end
end

%% --- PLOT 10-MIN ---
figure('Color','w');
barWidth = 0.8;
b = bar(data10.StartMin, data10.CallCount, barWidth, ...
        'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b.CData = barColors10;

% Label bins as ranges (e.g. "0–10")
xticks(data10.StartMin);
xlabels10 = strings(height(data10),1);
for i = 1:height(data10)
    xlabels10(i) = sprintf('%d to %d', round(data10.StartMin(i)), ...
                           round(data10.StartMin(i)+binWidth10));
end
set(gca,'XTickLabel',xlabels10,'XTickLabelRotation',45);

xlabel('Time window relative to Parturition (min)');
ylabel('Number of calls');
title('10-min Binned Calls');
grid on;
set(gca,'Box','off','Color','none','LineWidth',1,'FontSize',11);
ax = gca; ax.GridColor = [0.8 0.8 0.8];
xlim([startMinutes, max(data10.StartMin)+binWidth10]);

% --- LEGEND FOR PHASE COLORS ---
hold on;
bar_pre  = bar(nan, nan, 'FaceColor', color_pre,  'EdgeColor','k', 'LineWidth',1.2);
bar_par  = bar(nan, nan, 'FaceColor', color_par,  'EdgeColor','k', 'LineWidth',1.2);
bar_post = bar(nan, nan, 'FaceColor', color_post, 'EdgeColor','k', 'LineWidth',1.2);
legend([bar_pre, bar_par, bar_post], ...
       {'Pre-parturition', 'Parturition', 'Post-parturition'}, ...
       'Location', 'northwest', 'Box', 'off', 'FontSize', 10);

fig10 = gcf;  % or store the handle when you create the figure
save_if_missing(fig10, fullfile(outdir, 'AudSqueaks10'));

%% --- PLOT 20-MIN ---
figure('Color','w');
b2 = bar(data20.StartMin, data20.CallCount, barWidth, ...
         'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b2.CData = barColors20;

xticks(data20.StartMin);
xlabels20 = strings(height(data20),1);
for i = 1:height(data20)
    xlabels20(i) = sprintf('%d to %d', round(data20.StartMin(i)), ...
                           round(data20.StartMin(i)+binWidth20));
end
set(gca,'XTickLabel',xlabels20,'XTickLabelRotation',45);

xlabel('Time window relative to Parturition (min)');
ylabel('Number of calls');
title('20-min Binned Calls');
grid on;
set(gca,'Box','off','Color','none','LineWidth',1,'FontSize',11);
ax = gca; ax.GridColor = [0.8 0.8 0.8];
xlim([startMinutes, max(data20.StartMin)+binWidth20]);

% --- LEGEND FOR PHASE COLORS ---
hold on;
bar_pre  = bar(nan, nan, 'FaceColor', color_pre,  'EdgeColor','k', 'LineWidth',1.2);
bar_par  = bar(nan, nan, 'FaceColor', color_par,  'EdgeColor','k', 'LineWidth',1.2);
bar_post = bar(nan, nan, 'FaceColor', color_post, 'EdgeColor','k', 'LineWidth',1.2);
legend([bar_pre, bar_par, bar_post], ...
       {'Pre-parturition', 'Parturition', 'Post-parturition'}, ...
       'Location', 'northwest', 'Box', 'off', 'FontSize', 10);

fig20 = gcf;
save_if_missing(fig20, fullfile(outdir, 'AudSqueaks20'));

function save_if_missing(figHandle, basepath)
    % Ensure .fig extension
    if ~endsWith(basepath, '.fig', 'IgnoreCase', true)
        basepath = basepath + ".fig";
    end
    if ~isfile(basepath)
        savefig(figHandle, basepath);   % R2014b+
        fprintf('Saved: %s\n', basepath);
    else
        fprintf('Exists, not overwriting: %s\n', basepath);
    end
end

