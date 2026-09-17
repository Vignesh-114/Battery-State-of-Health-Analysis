%% Laptop Battery Health Check
% Reads Windows battery-report.html and calculates Battery SOH

clc;
clear;
close all;

%% 1. Locate Battery Report

userPath = getenv('USERPROFILE');
reportFile = fullfile(userPath, 'battery-report.html');

fprintf('Battery report location:\n%s\n\n', reportFile);

%% 2. Check File

if ~isfile(reportFile)
    error('Battery report not found. Run powercfg /batteryreport first.');
end

fprintf('Battery report found successfully.\n');

%% 3. Read HTML

html = fileread(reportFile);

fprintf('Battery report loaded successfully.\n\n');

%% 4. Remove HTML Tags

textData = regexprep(html, '<[^>]*>', ' ');
textData = strrep(textData, '&nbsp;', ' ');
textData = strrep(textData, '&amp;', '&');

% Convert multiple spaces into single spaces
textData = regexprep(textData, '\s+', ' ');

%% 5. Find Design Capacity

designPattern = 'DESIGN CAPACITY\s*([0-9,]+)\s*mWh';

designMatch = regexp(textData, designPattern, 'tokens', 'once');

if isempty(designMatch)
    % Try case-insensitive search
    designPattern = '(?i)DESIGN CAPACITY\s*([0-9,]+)\s*mWh';
    designMatch = regexp(textData, designPattern, 'tokens', 'once');
end

if isempty(designMatch)
    fprintf('\nCould not automatically detect Design Capacity.\n');
    fprintf('Searching battery report for capacity information...\n\n');

    capacityMatches = regexp(textData, ...
        '(?i)(DESIGN CAPACITY|FULL CHARGE CAPACITY)[^0-9]*([0-9,]+)\s*mWh', ...
        'tokens');

    disp(capacityMatches);

    error('Design Capacity format is different in your battery report.');
end

designCapacity = str2double(strrep(designMatch{1}, ',', ''));

%% 6. Find Full Charge Capacity

fullPattern = 'FULL CHARGE CAPACITY\s*([0-9,]+)\s*mWh';

fullMatch = regexp(textData, fullPattern, 'tokens', 'once');

if isempty(fullMatch)
    fullPattern = '(?i)FULL CHARGE CAPACITY\s*([0-9,]+)\s*mWh';
    fullMatch = regexp(textData, fullPattern, 'tokens', 'once');
end

if isempty(fullMatch)
    error('Full Charge Capacity could not be found.');
end

fullChargeCapacity = str2double(strrep(fullMatch{1}, ',', ''));

%% 7. Calculate Battery Health

batteryHealth = ...
    (fullChargeCapacity / designCapacity) * 100;

capacityLoss = ...
    designCapacity - fullChargeCapacity;

capacityLossPercent = ...
    (capacityLoss / designCapacity) * 100;

%% 8. Display Results

fprintf('============================================\n');
fprintf('       LAPTOP BATTERY HEALTH REPORT\n');
fprintf('============================================\n\n');

fprintf('Design Capacity      : %.0f mWh\n', ...
    designCapacity);

fprintf('Full Charge Capacity : %.0f mWh\n', ...
    fullChargeCapacity);

fprintf('Capacity Loss        : %.0f mWh\n', ...
    capacityLoss);

fprintf('Capacity Loss        : %.2f %%\n', ...
    capacityLossPercent);

fprintf('Battery Health (SOH) : %.2f %%\n', ...
    batteryHealth);

fprintf('\n============================================\n');

%% 9. Battery Health Status

if batteryHealth >= 90
    status = 'Excellent';
elseif batteryHealth >= 80
    status = 'Good';
elseif batteryHealth >= 70
    status = 'Moderate';
else
    status = 'Battery may need replacement';
end

fprintf('Battery Status       : %s\n', status);

fprintf('============================================\n');

%% 10. Create Graph

figure;

bar(batteryHealth);

ylim([0 100]);

ylabel('Battery Health (%)');
title('Laptop Battery Health / SOH');

grid on;

text(1, batteryHealth + 3, ...
    sprintf('%.2f%%', batteryHealth), ...
    'HorizontalAlignment', 'center', ...
    'FontSize', 14);

%% 11. Save Figure

saveas(gcf, 'battery_health.png');

fprintf('\nBattery health graph saved as:\n');
fprintf('battery_health.png\n');
