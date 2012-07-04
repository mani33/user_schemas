function subTrials = getSubTrialsByCondInd(key,conditions)

nRows = size(conditions,1);
subTrials = cell(size(conditions));

for iRow = 1:nRows
    cond =conditions(iRow,:);
    qs = sprintf('cond_idx in %s',util.array2csvStr(cond));
    subTrials(iRow,:) = fetchn(fle.SubTrials(key,qs),'subtrial_num');
end

if numel(conditions)==1
    subTrials = [subTrials{:}];
end
