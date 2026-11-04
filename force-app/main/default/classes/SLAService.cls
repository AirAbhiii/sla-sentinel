public with sharing class SLAService {

    public static String calculateLevel(
        Datetime dueDate,
        Datetime currentTime
    ) {

        Long minutesLeft =
            (dueDate.getTime() - currentTime.getTime()) / 60000;

        if (minutesLeft < 0) {
            return 'L3';
        }

        if (minutesLeft <= 60) {
            return 'L2';
        }

        if (minutesLeft <= 120) {
            return 'L1';
        }

        return 'None';
    }
}