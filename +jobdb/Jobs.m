%{
jobdb.Jobs (manual) # my newest table
job_id: smallint unsigned # blah
-----
init_script: varchar(256) # blah
run_script: varchar(256) # blah
status: smallint signed # blah
params: blob # params
priority: smallint signed # blah
submit_time: timestamp # blah
start_time = 0000-00-00 00-00-00: timestamp # blah
end_time = 0000-00-00 00-00-00: timestamp # blah
error_string = Null: blob # error string
error_stack = Null: blob # error stack
node = Null: varchar(250) # node name
%}

classdef Jobs < dj.Relvar
    
    properties(Constant)
        table = dj.Table('jobdb.Jobs')
    end
    
    methods
        function self = Jobs(varargin)
            self.restrict(varargin)
        end
    end
    methods(Static)
        function jr = getJobRelByFolder(folder)
            jKeys = fetch(jobdb.Jobs(sprintf('run_script="detect_spikes"')),'*');
            fl = length(folder);
            nKeys = length(jKeys);
            folders = cell(1,nKeys);
            for i = 1:nKeys
                p = jKeys(i).params{1};
                folders{i} = p(1:fl);
            end
            
            selInd = strcmp(folders,folder);
            ids = [jKeys(selInd).job_id];
            jr = jobdb.Jobs(sprintf('job_id in %s',util.array2csvStr(ids)));
        end
    end
end
