public with sharing class bigRideUtils {
    //Basically a bunch of stuff to make working with the data in big_ride__b
    //a lot simpler overall. 

    //helper class to perform async API requests easier
    public class asyncRequest{
        public string query{get;set;}
        public string operation{get;set;}
        public string targetObject{get;set;}
        public Map<string, string> targetFieldMap{get;set;}
        public Map<string, string> targetValueMap{get;set;}

        public asyncRequest(){
            targetFieldMap = new Map<String, string>();
            targetValueMap = new Map<string, string>();
        }
        public asyncRequest(string query, string operation, string targetObject, Map<string, string> TargetFieldMap){
            this.Query = query;
            this.Operation = operation;
            this.TargetObject = targetObject;
            this.TargetFieldMap = TargetFieldMap;
            targetValueMap = new Map<string, string>();
        }

        public asyncRequest(string query, string operation, string targetObject, Map<string, string> TargetFieldMap, Map<string, string> TargetValueMap){
            this.Query = query;
            this.Operation = operation;
            this.TargetObject = targetObject;
            this.TargetFieldMap = TargetFieldMap;
            this.TargetValueMap = TargetValueMap;
        }
    }

    //class to return a more prepared data set back to the LWC 'related list' component
    public class rideWrapper{
        @AuraEnabled public string ContactName {get;set;}
        @AuraEnabled public string contactURL{get;set;}
        @AuraEnabled public string Rental_UnitName{get;set;}
        @AuraEnabled public string unitURL{get;set;}
        @AuraEnabled public dateTime Start_Time{get;set;}
        @AuraEnabled public dateTime End_Time{get;set;}
        @AuraEnabled public string Trip_ID{get;set;}


        public rideWrapper(Big_Ride__b ride){
            Start_Time = ride.Start_Time__c;
            End_Time = ride.End_Time__c;
            Trip_ID = ride.Trip_ID__c;
        }
        public rideWrapper(){}
    }   
    //converts raw Big_Ride__b records to the wrapper class.
    public static List<rideWrapper> bikesToWrappers(List<Big_Ride__B> rideList){
        List<rideWrapper> finalList = new list<rideWrapper>();
        Map<Id,Contact> contactMap = new Map<Id,Contact>();
        Map<Id,Rental_Unit__c> unitMap = new Map<Id, Rental_Unit__c>();
        for(Big_Ride__b ride : rideList){
            contactMap.put(ride.contact__c, new Contact());
            unitMap.put(ride.rental_unit__c, new Rental_Unit__c());
        }
        for(Contact c : [select id, name from Contact where id in:contactMap.keySet()]){
            contactMap.put(c.id, c);
        }
        for(Rental_Unit__c r : [select id, name from Rental_Unit__c where id in :unitMap.keySet()]){
            unitMap.put(r.id, r);
        }
        for(Big_Ride__b ride : rideList){
            rideWrapper wrapper = new rideWrapper(ride);
            wrapper.contactName = contactMap.get(ride.contact__c).name;
            wrapper.Rental_UnitName = unitMap.get(ride.Rental_Unit__c).name;
            wrapper.contactURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Contact/' + ride.Contact__c + '/view';
            wrapper.unitURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Rental_Unit__c/' + ride.Rental_Unit__c + '/view';
            finalList.add(wrapper);
        }
        return finalList;
    }

    //Fetch and return big ride data, within the wrapper construct to make for good Lookup fields
    @AuraEnabled(cacheable=true)
    public static List<rideWrapper> getCustomRideRecords(string contactID){
        List<Big_Ride__b> rideList = [SELECT contact__c, rental_unit__c, start_location_lat__c, start_location_long__c,
                                        end_location_lat__c, end_location_long__c, start_time__c, end_time__c, trip_id__c
                                        FROM Big_Ride__b
                                        WHERE Contact__c = :contactID ORDER BY contact__c, start_time__c desc limit 10];
        //return rideList;
        List<rideWrapper> rideReturn = bikesToWrappers(rideList);
        return rideReturn;
    }

    /*Deprecated - not needed, using the custom one above
    @AuraEnabled(cacheable=true)
    public static List<Big_Ride__b> getCustomerRecentRideRecords(string contactID){
        List<Big_Ride__b> rideList = [SELECT contact__c, rental_unit__c, start_location_lat__c, start_location_long__c,
                                        end_location_lat__c, end_location_long__c, start_time__c, end_time__c, trip_id__c
                                        FROM Big_Ride__b
                                        WHERE Contact__c = :contactID ORDER BY contact__c, start_time__c desc limit 10];
        return rideList;
    }*/

    //Method to do an async SOQL call for the operating hours usecase: get all rides within a date range
    //to dump into an SOBject for further processing in Apex/Batch.
    public static void aqRidesByTimePeriod (Datetime startDate, Datetime endDate){

        string jobID;
        string URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v48.0/async-queries/';
        
        string startDateString = startDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
        string endDateString = endDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');

        string query = 'SELECT trip_id__c, rental_unit__c, contact__c, start_time__c, end_time__c FROM Big_Ride__b WHERE start_time__c > ' + 
                        startDateString + ' AND start_time__c < ' + endDateString;
        Map<String, string> fieldMap = new map<string,string>();
        fieldMap.put('trip_id__c', 'trip_id__c');
        fieldMap.put('rental_unit__c', 'rental_unit__c');
        fieldMap.put('contact__c', 'contact__c');
        fieldMap.put('start_time__c', 'start_time__c');
        fieldMap.put('end_time__c', 'end_time__c');
                
        bigRideUtils.asyncRequest requestBody = new bigRideUtils.asyncRequest(query, 'insert', 'Async_Ride__c', fieldMap);

        string requestBodyString = '{"query":"' + query + '", "operation":"insert", "targetObject":"Async_Ride__c", "targetFieldMap":' + json.Serialize(requestBody.targetFieldMap)+',"targetValueMap":{}}';
        system.debug(requestBodyString);

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();


        req.setEndpoint(URI);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json; charset=utf-8');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setBody(requestBodyString);

        try{
            res = http.send(req);
            System.debug('response');
            system.debug(res.toString());
            System.debug(res.getBody());
        }catch(System.CalloutException e){
            system.debug('error');
            system.debug(e);
            system.debug(res.toString());
        }
    }

    //Method to do an async SOQL call for the contact's report usecase: Scan full table, group by contact, 
    //join with rental_ride data. 
    public static void aqRidesByContactByProduct (){
        string query = 'SELECT Contact__c, Rental_Unit__r.product__c, COUNT(Trip_Id__c) c FROM Big_Ride__b GROUP BY Contact__c,Rental_Unit__r.product__c';
        string targetObject = 'Async_Aggregate_Calc__c';

        Map<string,string> fieldMap = new Map<string,string>();
        fieldMap.put('contact__c', 'contact__c');
        fieldMap.put('rental_unit__r.product__c', 'product__c');
        fieldMap.put('c', 'number_of_rides__c');

        executeAsyncJob(query, targetObject, fieldMap);
    }

    private static void executeAsyncJob(string query, string targetObject, Map<string, string> fieldMap){
        string jobID;
        string URI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v48.0/async-queries/';

        bigRideUtils.asyncRequest requestBody = new bigRideUtils.asyncRequest(query, 'insert', targetObject, fieldMap);

        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();

        string requestBodyString = '{"query":"' + query + '", "operation":"insert", "targetObject":"' +
            targetObject + '", "targetFieldMap":' + json.Serialize(requestBody.targetFieldMap)+',"targetValueMap":{}}';

        req.setEndpoint(URI);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json; charset=utf-8');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setBody(requestBodyString);

        try{
            res = http.send(req);
            System.debug('Job Locked and Loaded:');
            system.debug(res.toString());
            System.debug(res.getBody());
        }catch(System.CalloutException e){
            system.debug('error');
            system.debug(e);
            system.debug(res.toString());
        }
    }

    private static void wipeAsyncObject (string asyncObjectAPIName){
        //This is a destructive method to wipe out the sobject for async results. BP run before every async call.
        //Note this can only go up to 10k, so you'll need to flip to batch for bigger sets.
        List<Sobject> itemsToDelete = database.query('select id from ' + asyncObjectAPIName + ' Limit 10000');
        delete itemsToDelete;
    }
}
