function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'imc', 'mani_phys_imc');
end
obj = schemaObject;