%inputs: path

% import file containing data about stim times
times = uigetfile(fullfile(pathname,'low light','141002_arousal0.2V_light0.75V10sec.xls'));

%ultimately use uigetfile followed by uigetdata. Since my super shady
%method of import necessitates putting a dumb number of quotes on
%everything, let's just scroll through, and delete the ''s and then search.

% Alternatively, we could just find a way to conver the 2/10/14 system to
% the strings we actually need to search for. Honestly, that'll probably be
% a lot easier. let's go with that.