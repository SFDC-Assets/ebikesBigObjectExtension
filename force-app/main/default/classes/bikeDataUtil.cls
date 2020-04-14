public with sharing class bikeDataUtil {
    //This is all around things to make it easier to mass load dummy data into the big object.
    //Did you think storing a bajillion records was hard? Makin and uploading them isn't great either :D


    //Create rental bikes based off a random set of products in the org.
    public static void makeRentalBikes(integer numberOfBikes, string status){
        List<Rental_Unit__c> rentalInsertList = new list<Rental_Unit__c>();
        List<Product__c> bikeModels = [select id from product__c];
        integer chosenIndex = 0;
        for(integer x=0;x<numberOfBikes;x++){
            //randomly gen the product id
            chosenIndex = Integer.ValueOf(Math.rint(Math.random() * bikeModels.size()));
            if(chosenIndex == bikeModels.size()) chosenIndex--;
            Rental_Unit__c newUnit = new Rental_Unit__c(product__c=bikeModels[chosenIndex].id, unit_status__c=status);
            rentalInsertList.add(newUnit);
        }
        insert rentalInsertList;
    }

    //Method to generate Big_ride__b records, with just a bunch of randomization in em.
    public static void makeBObjectRides(Integer numberOfRides){
        List<Big_Ride__b> newRideRecords = new List<Big_Ride__b>();
        List<Rental_Unit__c> rentalUnits = [select id from Rental_Unit__c];
        List<Contact> contacts = [select id from Contact];
        Integer rentalIndex, contactIndex;
        for(Integer x=0;x<numberOfRides;x++){
            rentalIndex = Integer.ValueOf(Math.rint(Math.random()*rentalUnits.size()));
            contactIndex = Integer.ValueOf(Math.rint(Math.random()*contacts.size()));
            if(rentalIndex == rentalUnits.size()) rentalIndex--;
            if(contactIndex == contacts.size()) contactIndex--;
            newRideRecords.add(bikeDataUtil.generateBigRide(contacts[contactIndex].id, rentalUnits[rentalIndex].id));
        }
        List<Database.SaveResult> srs = Database.insertImmediate(newRideRecords);
        for(Database.SaveResult sr : srs){
            if(sr.isSuccess())
            {
                system.debug('Database insert succeeded ' + sr.getId());
            }else{
                for(Database.Error err : sr.getErrors()){
                    system.debug('Database insert failed somehow');
                    system.debug(err.getStatusCode() + ':' + err.getMessage());
                    system.debug('fields affected - ' + err.getFields());
                }
            }
        }
    }

    //Method to make bike rides you could predict - searching the big object table can be hard
    //if you feel that records SHOULD be there and aren't, something like this helps a lot to test methods with.
    public static void makePredictableBRides(Integer numberOfRides){
        List<Big_Ride__b> newRideRecords = new List<Big_Ride__b>();
        for(Integer x=0;x<numberOfRides;x++){
            string contactID = '';
            string rentalID = '';
            Big_Ride__b newBike = bikeDataUtil.generateBigRide(contactID, rentalID);
            newRideRecords.add(newBike);
        }
        
        List<Database.SaveResult> srs = Database.insertImmediate(newRideRecords);
        for(Database.SaveResult sr : srs){
            if(sr.isSuccess())
            {
                system.debug('Database insert succeeded ' + sr.getId());
            }else{
                for(Database.Error err : sr.getErrors()){
                    system.debug('Database insert failed somehow');
                    system.debug(err.getStatusCode() + ':' + err.getMessage());
                    system.debug('fields affected - ' + err.getFields());
                }
            }
        }
    }

    //I dont wanna re-remember this stupid algorithm every time
    private static Decimal randBetween(Decimal lowerBound, Decimal upperBound){
        Decimal range = Math.abs(upperBound-lowerBound);
        return (Math.random() * range + lowerBound);
    }

    //Actual random generation of the ride data. ALl sorts of fun.
    private static Big_Ride__b generateBigRide(string contactID, string RentalID){
        Big_Ride__b ride = new Big_Ride__b(contact__c=contactID, rental_unit__c=rentalID);
        Decimal startLatitude = randBetween(30.50139, 45.85694);
        Decimal endLatitude = randBetween(startLatitude-.1, startLatitude+.1);
        Decimal startLongitude= randBetween(-121.75583, -65.01197);
        Decimal endLongitude = randBetween(startLongitude-.1, startLongitude+.1);
        ride.start_location_lat__c = startLatitude;
        ride.start_location_long__c = startLongitude;
        ride.end_location_lat__c = endLatitude;
        ride.end_location_long__c = endLongitude;
        DateTime startTime = DateTime.newInstance(
            //Jan 1 2018 - Apr 1 2020
            (Long)Math.floor(randBetween(1514764800801.0,1585699200801.0))
        );
        DateTime endTime = startTime.addSeconds(Integer.valueOf(randBetween(108, 10800)));
        ride.start_time__c = startTime;
        ride.end_time__c = endTime;
        ride.trip_id__c = generateTripUUID();
        system.debug(ride);
        return ride;
    }
    //Generates a UUID for each row. FREAKING CRITICAL to do with big objects lemme tell ya.
    private static string generateTripUUID(){
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b);
        String guid = h.SubString(0,8) + '-' + h.SubString(8,12) + '-' + h.substring(12, 16) + '-' + h.substring(16, 20) + '-' + h.substring(20);
        return guid;
    }
}



