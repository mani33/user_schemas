function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'jobdb', 'jobdb');
end
obj = schemaObject;
