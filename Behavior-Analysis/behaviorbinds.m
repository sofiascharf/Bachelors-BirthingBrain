%% --- USER SETTINGS (match your call plots) ---
refTime      = datetime('21-Oct-2025 17:56:55','InputFormat','dd-MMM-yyyy HH:mm:ss'); % time = 0
startMinutes = -120;   % lower limit for x-axis
binWidth10   = 10;     % minutes (must match calls_10min_summary.csv)
binWidth20   = 20;     % minutes (must match calls_20min_summary.csv)

% Phase boundaries (in minutes)
baseline_start = -120;   % forced white
baseline_end   = -60;
parturition_start = 0;
parturition_end   = 15;

% Colors (same palette; baseline must be RGB to work with CData)
color_baseline = [1, 1, 1];          % white
color_pre  = [0.98, 0.31, 0.73];       % pre-parturition (−60..0)
color_par  = [0.75, 0, 0.75];        % 0..15
color_post = [0.494, 0.184, 0.556];  % >=15

%% --- LOAD EXISTING CALL BINS TO MIRROR WINDOWS EXACTLY ---
data10 = readtable('calls_10min_summary.csv');
data20 = readtable('calls_20min_summary.csv');

data10.BinCenter = datetime(data10.BinCenter,'InputFormat','dd-MMM-yyyy HH:mm:ss');
data20.BinCenter = datetime(data20.BinCenter,'InputFormat','dd-MMM-yyyy HH:mm:ss');

data10.StartMin = minutes(data10.BinCenter - refTime) - binWidth10/2;
data20.StartMin = minutes(data20.BinCenter - refTime) - binWidth20/2;

data10 = data10(data10.StartMin >= startMinutes, :);
data20 = data20(data20.StartMin >= startMinutes, :);

% Ensure a bin starting at t=0 exists (so colors/labels line up)
if ~ismember(0, data10.StartMin)
    newRow = array2table(zeros(1,width(data10)),'VariableNames',data10.Properties.VariableNames);
    newRow.BinCenter = refTime + minutes(binWidth10/2);
    newRow.StartMin  = 0;
    data10 = [data10; newRow];
end
if ~ismember(0, data20.StartMin)
    newRow = array2table(zeros(1,width(data20)),'VariableNames',data20.Properties.VariableNames);
    newRow.BinCenter = refTime + minutes(binWidth20/2);
    newRow.StartMin  = 0;
    data20 = [data20; newRow];
end

data10 = sortrows(data10,'StartMin');
data20 = sortrows(data20,'StartMin');

%% --- LOAD BEHAVIOR TIME SERIES ---
TS = readtable('timeseries_annotations.csv');   % EventDateTime, inside_nest, active_in_nest, outside_nest, etc.
TS.Minutes = minutes(TS.EventDateTime - refTime);

% Keep only the window we care about (a bit beyond last bin end for safety)
lastEnd10 = max(data10.StartMin) + binWidth10;
lastEnd20 = max(data20.StartMin) + binWidth20;
lastEnd   = max(lastEnd10, lastEnd20);
TS = TS(TS.Minutes >= startMinutes & TS.Minutes < lastEnd, :);

% ACTIVE-anywhere: active_in_nest OR outside_nest
TS.ActiveAnywhere = TS.active_in_nest | TS.outside_nest;

%% --- Helper to compute % in-bin for a logical vector at 1 s resolution ---
pctInBin = @(mins, logicalVec, bStart, bWidth) ...
    mean( logicalVec( mins >= bStart & mins < (bStart + bWidth) ) ) * 100;

%% --- Assign bin colors with BASELINE override ----------------------------
makeBarColors = @(starts, w) arrayfun(@(x) ...
    pickColorWithBaseline(x, baseline_start, baseline_end, ...
                              parturition_start, parturition_end, ...
                              color_baseline, color_pre, color_par, color_post), ...
    starts, 'UniformOutput', false);
colorMat = @(Ccell) vertcat(Ccell{:});

barColors10 = colorMat(makeBarColors(data10.StartMin, binWidth10));
barColors20 = colorMat(makeBarColors(data20.StartMin, binWidth20));

%% --- 1) % TIME IN NEST ---------------------------------------------------
pctInNest10 = arrayfun(@(s) pctInBin(TS.Minutes, TS.inside_nest, s, binWidth10), data10.StartMin);
pctInNest20 = arrayfun(@(s) pctInBin(TS.Minutes, TS.inside_nest, s, binWidth20), data20.StartMin);

% Plot 10-min
figure('Color','w');
barWidth = 0.8;
b = bar(data10.StartMin, pctInNest10, barWidth, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b.CData = barColors10;
xticks(data10.StartMin);
xlabels10 = strings(height(data10),1);
for i = 1:height(data10)
    xlabels10(i) = sprintf('%d to %d', round(data10.StartMin(i)), round(data10.StartMin(i)+binWidth10));
end
set(gca,'XTickLabel',xlabels10,'XTickLabelRotation',45);
xlabel('Time window relative to Parturition (min)');
ylabel('% of time in bin');
title('% Time IN Nest (10-min bins)');
grid on; box off; set(gca,'Color','none','LineWidth',1,'FontSize',11);
ax=gca; ax.GridColor=[0.8 0.8 0.8];
xlim([startMinutes, max(data10.StartMin)+binWidth10]);
ylim([0 100]);

% Plot 20-min
figure('Color','w');
b2 = bar(data20.StartMin, pctInNest20, barWidth, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b2.CData = barColors20;
xticks(data20.StartMin);
xlabels20 = strings(height(data20),1);
for i = 1:height(data20)
    xlabels20(i) = sprintf('%d to %d', round(data20.StartMin(i)), round(data20.StartMin(i)+binWidth20));
end
set(gca,'XTickLabel',xlabels20,'XTickLabelRotation',45);
xlabel('Time window relative to Parturition (min)');
ylabel('% of time in bin');
title('% Time IN Nest (20-min bins)');
grid on; box off; set(gca,'Color','none','LineWidth',1,'FontSize',11);
ax=gca; ax.GridColor=[0.8 0.8 0.8];
xlim([startMinutes, max(data20.StartMin)+binWidth20]);
ylim([0 100]);


%% --- 2) % TIME ACTIVE (active_in_nest OR outside_nest) -------------------
pctActive10 = arrayfun(@(s) pctInBin(TS.Minutes, TS.ActiveAnywhere, s, binWidth10), data10.StartMin);
pctActive20 = arrayfun(@(s) pctInBin(TS.Minutes, TS.ActiveAnywhere, s, binWidth20), data20.StartMin);

% Plot 10-min
figure('Color','w');
b = bar(data10.StartMin, pctActive10, barWidth, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b.CData = barColors10;
xticks(data10.StartMin);
set(gca,'XTickLabel',xlabels10,'XTickLabelRotation',45);
xlabel('Time window relative to Parturition (min)');
ylabel('% of time in bin');
title('% Time ACTIVE (10-min bins)');
grid on; box off; set(gca,'Color','none','LineWidth',1,'FontSize',11);
ax=gca; ax.GridColor=[0.8 0.8 0.8];
xlim([startMinutes, max(data10.StartMin)+binWidth10]);
ylim([0 100]);

% Plot 20-min
figure('Color','w');
b2 = bar(data20.StartMin, pctActive20, barWidth, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b2.CData = barColors20;
xticks(data20.StartMin);
set(gca,'XTickLabel',xlabels20,'XTickLabelRotation',45);
xlabel('Time window relative to Parturition (min)');
ylabel('% of time in bin');
title('% Time ACTIVE (20-min bins)');
grid on; box off; set(gca,'Color','none','LineWidth',1,'FontSize',11);
ax=gca; ax.GridColor=[0.8 0.8 0.8];
xlim([startMinutes, max(data20.StartMin)+binWidth20]);
ylim([0 100]);

%% --- 3) % TIME CIRCLING (anywhere) --------------------------------------
vars = string(TS.Properties.VariableNames);
circCols = contains(lower(vars), 'circling');
if any(circCols)
    TS.CirclingAnywhere = false(height(TS),1);
    for v = vars(circCols)
        TS.CirclingAnywhere = TS.CirclingAnywhere | TS.(v);
    end
else
    warning('No columns containing "circling" found in timeseries_annotations.csv. Using zeros.');
    TS.CirclingAnywhere = false(height(TS),1);
end

pctCircling10 = arrayfun(@(s) pctInBin(TS.Minutes, TS.CirclingAnywhere, s, binWidth10), data10.StartMin);
pctCircling20 = arrayfun(@(s) pctInBin(TS.Minutes, TS.CirclingAnywhere, s, binWidth20), data20.StartMin);

% Plot 10-min
figure('Color','w');
b = bar(data10.StartMin, pctCircling10, barWidth, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b.CData = barColors10;
xticks(data10.StartMin);
set(gca,'XTickLabel',xlabels10,'XTickLabelRotation',45);
xlabel('Time window relative to Parturition (min)');
ylabel('% of time in bin');
title('% Time CIRCLING (10-min bins)');
grid on; box off; set(gca,'Color','none','LineWidth',1,'FontSize',11);
xlim([startMinutes, max(data10.StartMin)+binWidth10]); ylim([0 100]);

% Plot 20-min
figure('Color','w');
b2 = bar(data20.StartMin, pctCircling20, barWidth, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b2.CData = barColors20;
xticks(data20.StartMin);
set(gca,'XTickLabel',xlabels20,'XTickLabelRotation',45);
xlabel('Time window relative to Parturition (min)');
ylabel('% of time in bin');
title('% Time CIRCLING (20-min bins)');
grid on; box off; set(gca,'Color','none','LineWidth',1,'FontSize',11);
xlim([startMinutes, max(data20.StartMin)+binWidth20]); ylim([0 100]);

%% --- 4) % TIME NESTING (anywhere) ---------------------------------------
nestCols = contains(lower(vars), 'nesting');
if any(nestCols)
    TS.NestingAnywhere = false(height(TS),1);
    for v = vars(nestCols)
        TS.NestingAnywhere = TS.NestingAnywhere | TS.(v);
    end
else
    warning('No columns containing "nesting" found in timeseries_annotations.csv. Using zeros.');
    TS.NestingAnywhere = false(height(TS),1);
end

pctNesting10 = arrayfun(@(s) pctInBin(TS.Minutes, TS.NestingAnywhere, s, binWidth10), data10.StartMin);
pctNesting20 = arrayfun(@(s) pctInBin(TS.Minutes, TS.NestingAnywhere, s, binWidth20), data20.StartMin);

% Plot 10-min
figure('Color','w');
b = bar(data10.StartMin, pctNesting10, barWidth, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b.CData = barColors10;
xticks(data10.StartMin);
set(gca,'XTickLabel',xlabels10,'XTickLabelRotation',45);
xlabel('Time window relative to Parturition (min)');
ylabel('% of time in bin');
title('% Time NESTING (10-min bins)');
grid on; box off; set(gca,'Color','none','LineWidth',1,'FontSize',11);
xlim([startMinutes, max(data10.StartMin)+binWidth10]); ylim([0 100]);

% Plot 20-min
figure('Color','w');
b2 = bar(data20.StartMin, pctNesting20, barWidth, 'FaceColor','flat', 'EdgeColor','k', 'LineWidth',1.2);
b2.CData = barColors20;
xticks(data20.StartMin);
set(gca,'XTickLabel',xlabels20,'XTickLabelRotation',45);
xlabel('Time window relative to Parturition (min)');
ylabel('% of time in bin');
title('% Time NESTING (20-min bins)');
grid on; box off; set(gca,'Color','none','LineWidth',1,'FontSize',11);
xlim([startMinutes, max(data20.StartMin)+binWidth20]); ylim([0 100]);

%% --- HELPERS -------------------------------------------------------------
function c = pickColorWithBaseline(startMin, bStart, bEnd, pStart, pEnd, cBase, cPre, cPar, cPost)
    % Baseline override first
    if startMin >= bStart && startMin < bEnd
        c = cBase;
    elseif startMin < pStart
        % Pre is now effectively [-60..0) because baseline is white
        c = cPre;
    elseif startMin >= pStart && startMin < pEnd
        c = cPar;
    else
        c = cPost;
    end
end

