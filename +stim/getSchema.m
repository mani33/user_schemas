function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'stim', 'mani_stim');
end
obj = schemaObject;
