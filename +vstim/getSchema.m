function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'vstim', 'mani_stim_util');
end
obj = schemaObject;
