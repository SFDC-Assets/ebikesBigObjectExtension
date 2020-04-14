global class aqDeleteTableContents implements Database.Batchable<SObject>{
    //When workin with big data, things get messy - this is a handy tool to just purge
    //an overgrown object without actually doing a truncate.
    global final string objectToDelete;

    global aqDeleteTableContents(string objectAPINameToDelete){
        this.objectToDelete = objectAPINameToDelete;
    }

    global Database.QueryLocator start(Database.BatchableContext bc){
        string query = 'SELECT Id from ' + objectToDelete;
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        delete scope;
    }

    global void finish (Database.BatchableContext bc){

    }
}

