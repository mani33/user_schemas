function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'sess', 'mani_sess');
end
obj = schemaObject;
