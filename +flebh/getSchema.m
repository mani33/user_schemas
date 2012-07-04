function obj = getSchema
% flebm - Flash lag experiment behavior monkey
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'flebh', 'mani_fle_beh_hum');
end
obj = schemaObject;
