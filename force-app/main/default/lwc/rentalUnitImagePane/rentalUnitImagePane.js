import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import rentalProductDetails from '@salesforce/apex/rentalRideUtils.rentalProductDetails';


export default class RentalUnitImagePane extends LightningElement {
    @api recordId;

    @wire(rentalProductDetails, {rentalUnitID: '$recordId'})
    productRecord;

}