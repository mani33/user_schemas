function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'fle', 'mani_phys_fle');
end
obj = schemaObject;
