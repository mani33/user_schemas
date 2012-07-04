function rf_size = get2dRfSize(eKeys)
% function rf_size = get2dRfSize(eKeys)
%
% Using dotmapping, finds the 2d rf size. Input ekeys should be from Flash Lag Experiment

nKeys = length(eKeys);
rf_size = nan(1,nKeys);
tic
for iKey = 1:nKeys
    rf_key = fetch1(fle.DotmapLink(eKeys(iKey)),'dotmap_key');
    if ~isempty(rf_key)
    rf_size(iKey) = fetch1(rf.Size(rf_key,'map_type_num=3 and mahal_dist=1'),'size');
    end
end
toc