function obj = getSchema
% flebm - Flash lag experiment behavior monkey
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'flebm', 'mani_fle_beh_mon');
end
obj = schemaObject;
