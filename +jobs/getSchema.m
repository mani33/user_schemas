function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'jobs', 'mani_jobs');
end
obj = schemaObject;
