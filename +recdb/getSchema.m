function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'recdb', 'recdb');
end
obj = schemaObject;
