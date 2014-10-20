function new_dates = formatDates(stim_times)

[dates, times] = textread(stim_times,'%s %s'); %#ok<*DTXTRD>

calendar = {'Jan' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'};

new_dates = cell(length(dates),2);

for i = 1:length(dates)
    % Convert each number into a string for that month
    month = str2num(dates{i}(1:2));
    month = calendar{month};
    
    % Extract the day; ignore the first zero
    day = dates{i}(4:5);
    if day (1) == '0'
        day = day(2);
    end
    
    % Extract the year
    yr = dates{i}(9:10);
    
    % Combine it all together into a new string!
    new_dates{i,1} = [day, ' ', month, ' ', yr];
    new_dates{i,2} = times{i};
    
end
    
    