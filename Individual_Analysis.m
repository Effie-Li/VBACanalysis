function record = parseData(participant)
    
    % find exp1, exp2 data files
    folder = strcat('VBAC_',int2str(participant));
    files = dir(folder);
    files = {files.name};
    re = strcat('_',int2str(participant),'.csv');
    i = regexp(files,re);
    i = ~cellfun('isempty',i);
    files = files(i);
    
    f1 = char(files(~cellfun('isempty',regexp(files,'Experiment1'))));
    f2 = char(files(~cellfun('isempty',regexp(files,'Experiment2'))));
    f1 = strcat(folder, '/', f1);
    f2 = strcat(folder, '/', f2);
    E1 = readCSV(f1);
    E2 = readCSV(f2);
    
    record = struct('subjNum', participant);
    record.testTime = char(E1{2}{2});
    record.group = groupAssignment(participant);
    
    % turn each experiment to a struct
    S1 = expToStruct(E1, f1);
    S2 = expToStruct(E2, f2);
    
    record.Experiment1 = S1;
    record.Experiment2 = S2;
    
    % add fields to experiments
    record = addFields(record);
    
end

function E = readCSV(filename)
    f = fopen(filename);
    E = textscan(f, '%s', 'delimiter', '\n');
    E = E{1};
    E = strcat(',',E);
    E = regexp(E, ',([^,]*)', 'tokens');
end

function group = groupAssignment(participant)
    r = mod(participant,4);
    if r <= 1
        group = 'experimental';
    else
        group = 'control';
    end
end

function [S] = expToStruct(exp, filename)
    S = struct('rawDataFile',filename);
    [nrow,ncol] = size(exp);
    headers = exp{1,1};
    [a,b]=size(headers);
    for i = 1:b-1
        header = char(headers{i});
        row = [];
        for j = 2:nrow
            row = [row; exp{j}{i}];
        end
        % format data type
        if ~any([strcmp(header,'targetColor'),...
                strcmp(header,'valueDistractorColor'),...
                strcmp(header,'targetShape'),...
                strcmp(header,'trialStartTime')])
            row = str2double(row);
        end
        if strcmp(header, 'trialStartTime')
            row = datevec(row);
        end
        S.(header) = row;
    end
end

function S = addFields(S)

    S.Experiment1.missedTrial = isnan(S.Experiment1.response);
    S.Experiment1.correctTrial = (S.Experiment1.targetOrientation==0 & S.Experiment1.response==7)...
                                | (S.Experiment1.targetOrientation==90 & S.Experiment1.response==6);
    S.Experiment2.missedTrial = isnan(S.Experiment2.response);
    S.Experiment2.correctTrial = (S.Experiment2.targetOrientation==0 & S.Experiment2.response==7)...
                                |(S.Experiment2.targetOrientation==90 & S.Experiment2.response==6);

    if strcmp(S.group,'control')
    % Experiment 1 %
        S.Experiment1.greenTargetTrial = strcmp(S.Experiment1.targetColor,'lime');
        S.Experiment1.redTargetTrial = strcmp(S.Experiment1.targetColor,'red');
        
        % accuracy
        agtt = sum(S.Experiment1.greenTargetTrial & S.Experiment1.correctTrial)...
                /(sum(S.Experiment1.greenTargetTrial)...
                -sum(S.Experiment1.greenTargetTrial & S.Experiment1.missedTrial));
        artt = sum(S.Experiment1.redTargetTrial & S.Experiment1.correctTrial)...
                /(sum(S.Experiment1.redTargetTrial)...
                -sum(S.Experiment1.redTargetTrial & S.Experiment1.missedTrial));
        S.Experiment1.accuracy = struct('greenTargetTrial',agtt);
        S.Experiment1.accuracy.redTargetTrial = artt;
        S.Experiment1.accuracy.overall = sum(S.Experiment1.correctTrial)/(240-sum(S.Experiment1.missedTrial));
        
        % RTs
        S.Experiment1.RT(S.Experiment1.missedTrial) = NaN;
        rtptp = nanmean(S.Experiment1.RT(S.Experiment1.greenTargetTrial & S.Experiment1.correctTrial));
        rtpta = nanmean(S.Experiment1.RT(S.Experiment1.redTargetTrial & S.Experiment1.correctTrial));
        S.Experiment1.RTs = struct('greenTargetTrial',rtptp);
        S.Experiment1.RTs.redTargetTrial = rtpta;
        S.Experiment1.RTs.overall = nanmean(S.Experiment1.RT(S.Experiment1.correctTrial));
        
        % no response
        S.Experiment1.noResponse = struct('numGreenTarget',sum(S.Experiment1.greenTargetTrial & S.Experiment1.missedTrial));
        S.Experiment1.noResponse.propGreenTarget = S.Experiment1.noResponse.numGreenTarget / sum(S.Experiment1.greenTargetTrial);
        S.Experiment1.noResponse.numRedTarget = sum(S.Experiment1.redTargetTrial & S.Experiment1.missedTrial);
        S.Experiment1.noResponse.propRedTarget = S.Experiment1.noResponse.numRedTarget / sum(S.Experiment1.redTargetTrial);
    
    % Experiment 2 %
        S.Experiment2.previousTargetPresent = strcmp(S.Experiment2.valueDistractorColor,'lime') ...
                                            | strcmp(S.Experiment2.valueDistractorColor, 'red');
        S.Experiment2.previousTargetAbsent = ~S.Experiment2.previousTargetPresent;
        
        % accuracy
        aptp = sum(S.Experiment2.previousTargetPresent & S.Experiment2.correctTrial)...
                /(sum(S.Experiment2.previousTargetPresent)...
                 -sum(S.Experiment2.previousTargetPresent & S.Experiment2.missedTrial))
        apta = sum(S.Experiment2.previousTargetAbsent & S.Experiment2.correctTrial)...
                /(sum(S.Experiment2.previousTargetAbsent)...
                 -sum(S.Experiment2.previousTargetAbsent & S.Experiment2.missedTrial));
        S.Experiment2.accuracy = struct('previousTargetPresent',aptp);
        S.Experiment2.accuracy.previousTargetAbsent = apta;
        S.Experiment2.accuracy.overall = sum(S.Experiment2.correctTrial)/(240-sum(S.Experiment2.missedTrial));
             
        % RTs
        S.Experiment2.RT(S.Experiment2.missedTrial) = NaN;
        rtptp = nanmean(S.Experiment2.RT(S.Experiment2.previousTargetPresent & S.Experiment2.correctTrial));
        rtpta = nanmean(S.Experiment2.RT(S.Experiment2.previousTargetAbsent & S.Experiment2.correctTrial));
        S.Experiment2.RTs = struct('previousTargetPresent',rtptp);
        S.Experiment2.RTs.previousTargetAbsent = rtpta;
        S.Experiment2.RTs.overall = nanmean(S.Experiment2.RT(S.Experiment2.correctTrial));
        
        % no response
        S.Experiment2.noResponse = struct('numPreviousTargetPresent',sum(S.Experiment2.previousTargetPresent & S.Experiment2.missedTrial));
        S.Experiment2.noResponse.propPreviousTargetPresent = S.Experiment2.noResponse.numPreviousTargetPresent / sum(S.Experiment2.previousTargetPresent);
        S.Experiment2.noResponse.numPreviousTargetAbsent = sum(S.Experiment2.previousTargetAbsent & S.Experiment2.missedTrial);
        S.Experiment2.noResponse.propRedTarget = S.Experiment2.noResponse.numPreviousTargetAbsent / sum(S.Experiment2.previousTargetAbsent);
        
    elseif strcmp(S.group,'experimental')
        
        
    end
end