global class aqBatchHoursByUnit implements Database.Batchable<SObject>{

    //Batch processor to take records outputted by Async SOQL, and process operating hours from them.
    //Basically, extract a subset of your big object, run Batch to do additional calculations, and store that in the 
    //normal SObjects for workflows, etc.

    global Database.QueryLocator start(Database.BatchableContext bc){
        string query = 'SELECT Id, rental_unit__c, contact__c, trip_id__c, start_time__c, end_time__c FROM Async_ride__c';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope){
        set<string> rentalIDs = new set<string>();
        for(sobject ride : scope){
            rentalIds.add((string)ride.get('rental_unit__c'));
        }

        List<Rental_Unit__c> rentalUnits = [select id, operating_hours__c from Rental_Unit__c where id in:rentalIDs];
        Map<string, rental_unit__c> rentalMap = new map<string, rental_unit__c>();
        for(Rental_unit__c unit : rentalUnits){
            rentalMap.put(unit.id, unit);
        }

        for(sobject ride : scope){
            DateTime startTime = (DateTime)ride.get('start_time__c');
            DateTime endTime = (DateTime)ride.get('end_time__c');
            long operatingHours = (endTime.getTime() - startTime.getTime())/1000/60/60;
            rentalMap.get((string)ride.get('rental_unit__c')).operating_hours__c += operatingHours;
        }
        update rentalMap.values();
    }

    global void finish (Database.BatchableContext bc){

    }
}
