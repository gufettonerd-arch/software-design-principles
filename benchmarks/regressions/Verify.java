package bench;

import java.lang.reflect.Method;
import java.util.Map;

// Injected into a run's src/main/java/bench/ only for scoring, then removed.
// Not part of either arm's own work. Calls GodClass.calculateLatePaymentPenalty
// with the same inputs used to compute the pre-change reference values, and
// diffs the outputs.
public class Verify {
    public static void main(String[] args) throws Exception {
        Map<String, GodClass.Customer> customers = Map.of(
            "c1", new GodClass.Customer("c1", "GOLD"),
            "c2", new GodClass.Customer("c2", "BRONZE"),
            "c3", new GodClass.Customer("c3", "SILVER")
        );
        Map<String, GodClass.Order> orders = Map.of(
            "o-small", new GodClass.Order("o-small", 30.0),
            "o-large", new GodClass.Order("o-large", 200.0)
        );

        Object[][] cases = {
            {"c1", "o-large", 3, 6.0},
            {"c1", "o-large", 10, 40.0},
            {"c2", "o-large", 3, 12.0},
            {"c1", "o-small", 100, 12.0},
            {"c1", "o-large", 0, 0.0},
            {"c3", "o-large", 7, 28.0},
        };

        Method m;
        try {
            m = GodClass.class.getMethod("calculateLatePaymentPenalty", String.class, String.class, int.class);
        } catch (NoSuchMethodException e) {
            System.out.println("VERIFY_STATUS=method-not-on-godclass");
            return;
        }

        GodClass god = new GodClass(customers, orders);
        boolean allMatch = true;
        for (Object[] c : cases) {
            double actual = (double) m.invoke(god, c[0], c[1], c[2]);
            double expected = (double) c[3];
            if (Math.abs(actual - expected) > 0.001) {
                allMatch = false;
                System.out.println("MISMATCH " + c[0] + "," + c[1] + "," + c[2]
                    + " expected=" + expected + " actual=" + actual);
            }
        }
        System.out.println("VERIFY_STATUS=" + (allMatch ? "behavior-preserved" : "behavior-changed"));
    }
}
