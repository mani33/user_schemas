function obj = getSchema
persistent schemaObject
if isempty(schemaObject)
        schemaObject = dj.Schema(dj.conn,'flevbl', 'mani_phys_fle_var_bar_lum');
end
obj = schemaObject;
