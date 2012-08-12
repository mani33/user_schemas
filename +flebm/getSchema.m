function obj = getSchema
% flebm - Flash lag experiment behavior monkey
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn,'flebm', 'mani_beh_fle_mon');
end
obj = schemaObject;
