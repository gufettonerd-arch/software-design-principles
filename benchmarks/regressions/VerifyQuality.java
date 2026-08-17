package bench;

import java.lang.reflect.Method;
import java.util.Map;

// Injected into a run's src/main/java/bench/ only for scoring, then removed.
// Calls GodClass.chkShipElig with the same inputs used in GodClassTest's
// shipElig_* cases and diffs the outputs — a Step 7 readability pass must
// not change behavior, only clarity.
public class VerifyQuality {
    public static void main(String[] args) throws Exception {
        Map<String, GodClass.Customer> customers = Map.of(
            "c1", new GodClass.Customer("c1", "GOLD"),
            "c2", new GodClass.Customer("c2", "BRONZE"),
            "c3", new GodClass.Customer("c3", "SILVER")
        );
        Map<String, GodClass.Order> orders = Map.of(
            "o-small", new GodClass.Order("o-small", 30.0),
            "o-large", new GodClass.Order("o-large", 200.0),
            "o-tiny", new GodClass.Order("o-tiny", 15.0)
        );

        Object[][] cases = {
            {"c1", "o-large", 0.0, "IT", false},
            {"c1", "o-large", 35.0, "IT", false},
            {"c1", "o-large", 10.0, null, false},
            {"c1", "o-large", 10.0, "IT", true},
            {"c1", "o-tiny", 10.0, "IT", true},
            {"c2", "o-tiny", 10.0, "IT", false},
            {"c1", "o-large", 3.0, "US", true},
            {"c1", "o-large", 10.0, "US", false},
        };

        Method m;
        try {
            m = GodClass.class.getMethod("chkShipElig", String.class, String.class, double.class, String.class);
        } catch (NoSuchMethodException e) {
            System.out.println("VERIFY_STATUS=method-not-on-godclass");
            return;
        }

        GodClass god = new GodClass(customers, orders);
        boolean allMatch = true;
        for (Object[] c : cases) {
            boolean actual = (boolean) m.invoke(god, c[0], c[1], c[2], c[3]);
            boolean expected = (boolean) c[4];
            if (actual != expected) {
                allMatch = false;
                System.out.println("MISMATCH " + c[0] + "," + c[1] + "," + c[2] + "," + c[3]
                    + " expected=" + expected + " actual=" + actual);
            }
        }
        System.out.println("VERIFY_STATUS=" + (allMatch ? "behavior-preserved" : "behavior-changed"));
    }
}
