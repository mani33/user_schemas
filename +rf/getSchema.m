function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'rf', 'mani_rf2d');
end
obj = schemaObject;
