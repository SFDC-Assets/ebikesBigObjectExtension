public class queueBikeDataUtil implements Queueable{
    //This class sets up a queueable implementation so you can queue the hell outta the ride data builder.
    //Used by the setup process, but also could be done later as needed to just generate rides in bulk.
    public void execute(QueueableContext qc){
        bikeDataUtil.makeBObjectRides(10000);
    }
}
