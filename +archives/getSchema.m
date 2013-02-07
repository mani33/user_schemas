function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'archives', 'mani_archives');
end
obj = schemaObject;
