public class queueBikeDataUtil implements Queueable{
    public void execute(QueueableContext qc){
        bikeDataUtil.makeBObjectRides(10000);
        
    }
}
