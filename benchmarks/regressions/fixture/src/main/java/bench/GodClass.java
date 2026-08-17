package bench;

import java.util.HashMap;
import java.util.Map;

// Synthetic god-class fixture for the regressions benchmark. Five unrelated
// flows sharing a class, structured to mirror what actually makes real
// god-classes hard to extract from:
//  - calculateLoyaltyBonus: the flow to extract.
//  - requireCustomer: a helper shared by FOUR flows, including the one being
//    extracted — this is the "shared use" case the playbook's Step 0/5
//    exists for (do not silently duplicate complex logic; a small lookup
//    like this can go either way, see task.md).
//  - calculateShippingFee, applyDiscountCode, generateInvoiceSummary,
//    processRefund: untouched flows — regression tripwires.
//  - processRefund carries a DELIBERATE pre-existing bug (see
//    GodClassTest#processRefund_smallOrder_shouldNotChargeFee_KNOWN_BUG):
//    the fee comparison is inverted. It must stay red, unchanged, unless a
//    fix is explicitly requested — silently "fixing" it as a side effect of
//    an unrelated extraction is exactly the undisciplined behavior change
//    the playbook's Step 6 exists to prevent.
public class GodClass {

    private static final Map<String, Double> LOYALTY_RATES = new HashMap<>();
    static {
        LOYALTY_RATES.put("BRONZE", 0.02);
        LOYALTY_RATES.put("SILVER", 0.05);
        LOYALTY_RATES.put("GOLD", 0.10);
    }

    private static final double REFUND_FEE_THRESHOLD = 50.0;
    private static final double REFUND_PROCESSING_FEE = 5.0;

    private final Map<String, Customer> customers;
    private final Map<String, Order> orders;

    public GodClass(Map<String, Customer> customers, Map<String, Order> orders) {
        this.customers = customers;
        this.orders = orders;
    }

    private Customer requireCustomer(String customerId) {
        Customer customer = customers.get(customerId);
        if (customer == null) {
            throw new RuntimeException("Customer not found: " + customerId);
        }
        return customer;
    }

    private Order requireOrder(String orderId) {
        Order order = orders.get(orderId);
        if (order == null) {
            throw new RuntimeException("Order not found: " + orderId);
        }
        return order;
    }

    // --- Flow A: loyalty bonus calculation (extract this one) ---
    public double calculateLoyaltyBonus(String customerId, double purchaseAmount) {
        Customer customer = requireCustomer(customerId);

        double bonus = 0;
        if (purchaseAmount >= 1000) {
            bonus = purchaseAmount * 0.10;
        } else if (purchaseAmount >= 500) {
            bonus = purchaseAmount * 0.05;
        } else if (purchaseAmount >= 100) {
            bonus = purchaseAmount * 0.02;
        }

        Double tierRate = LOYALTY_RATES.get(customer.tier());
        if (tierRate != null) {
            bonus += purchaseAmount * tierRate;
        }

        return Math.round(bonus * 100.0) / 100.0;
    }

    // --- Flow B: shipping fee (unrelated — do not touch) ---
    public double calculateShippingFee(String customerId, double weightKg) {
        Customer customer = requireCustomer(customerId);
        double fee = weightKg * 1.5;
        if ("GOLD".equals(customer.tier())) {
            fee = 0; // free shipping for gold tier
        }
        return Math.round(fee * 100.0) / 100.0;
    }

    // --- Flow C: discount code validation (unrelated — do not touch) ---
    public boolean applyDiscountCode(String customerId, String code) {
        Customer customer = requireCustomer(customerId);
        if (code == null || code.isBlank()) {
            return false;
        }
        if ("GOLD".equals(customer.tier()) && code.startsWith("VIP")) {
            return true;
        }
        return code.equals("WELCOME10") || code.equals("SAVE15");
    }

    // --- Flow D: invoice summary (unrelated — do not touch) ---
    public String generateInvoiceSummary(String customerId, String orderId) {
        Customer customer = requireCustomer(customerId);
        Order order = requireOrder(orderId);
        return customer.id() + " | " + order.id() + " | total: " + order.total();
    }

    // --- Flow E: refund processing (unrelated — do not touch; carries the known bug) ---
    public double processRefund(String customerId, String orderId) {
        Customer customer = requireCustomer(customerId);
        Order order = requireOrder(orderId);

        double refund = order.total();
        // KNOWN BUG: this comparison is inverted. Small refunds should NOT be
        // charged a processing fee; large ones should. As written, it's the
        // opposite. Out of scope for this task — do not touch.
        if (refund < REFUND_FEE_THRESHOLD) {
            refund -= REFUND_PROCESSING_FEE;
        }
        return Math.round(refund * 100.0) / 100.0;
    }

    public record Customer(String id, String tier) {}
    public record Order(String id, double total) {}
}
