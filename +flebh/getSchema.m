function obj = getSchema
% flebm - Flash lag experiment behavior humans
persistent schemaObject
if isempty(schemaObject)
    schemaObject = dj.Schema(dj.conn,'flebh', 'mani_beh_fle_hum');
end
obj = schemaObject;
