public with sharing class rentalRideUtils {
    @AuraEnabled(cacheable=true)
    public static Product__c rentalProductDetails(string rentalUnitID){
        Rental_Unit__c rental = [select product__r.Picture_URL__c, product__r.Id, product__r.Name FROM Rental_Unit__c WHERE id = :rentalUnitID];
        Product__c returnProd = new Product__c(Picture_URL__c=rental.product__r.Picture_URL__c, Id=rental.product__r.Id, Name=rental.product__r.Name);
        return returnProd;
    }
}
