public with sharing class bigRideUtils {
    
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

    @AuraEnabled(cacheable=true)
    public static List<Big_Ride__b> getCustomerRecentRideRecords(string contactID){
        List<Big_Ride__b> rideList = [SELECT contact__c, rental_unit__c, start_location_lat__c, start_location_long__c,
                                        end_location_lat__c, end_location_long__c, start_time__c, end_time__c, trip_id__c
                                        FROM Big_Ride__b
                                        WHERE Contact__c = :contactID ORDER BY contact__c, start_time__c desc limit 25];
        return rideList;
    }

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
            System.debug('response');
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
