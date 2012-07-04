function val = getSubTrialParams(key,paramNames,subTrials)

nParams = numel(paramNames);
if nParams == 1
    paramNames = {paramNames};
end

qs = sprintf('subtrial_num in %s',util.array2csvStr(subTrials));
val = cell(1,nParams);

for iParam = 1:nParams
    val{iParam} = fetchn(fle.SubTrials(key,qs),paramNames{iParam});
end

if nParams==1
    val = [val{:}];
end
