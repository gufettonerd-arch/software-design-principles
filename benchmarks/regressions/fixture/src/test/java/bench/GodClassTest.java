package bench;

import org.junit.jupiter.api.Test;
import java.util.Map;
import static org.junit.jupiter.api.Assertions.*;

// Baseline snapshot: 17 passing, 1 deliberately failing (documented known
// bug in processRefund — see GodClass). That one test must stay red,
// unchanged, after the extraction. See task.md.
class GodClassTest {

    private final GodClass god = new GodClass(
        Map.of(
            "c1", new GodClass.Customer("c1", "GOLD"),
            "c2", new GodClass.Customer("c2", "BRONZE"),
            "c3", new GodClass.Customer("c3", "SILVER")
        ),
        Map.of(
            "o-small", new GodClass.Order("o-small", 30.0),
            "o-large", new GodClass.Order("o-large", 200.0),
            "o-tiny", new GodClass.Order("o-tiny", 15.0)
        )
    );

    // --- calculateLoyaltyBonus (the flow to extract) ---

    @Test
    void loyaltyBonus_goldTier_highPurchase() {
        assertEquals(200.0, god.calculateLoyaltyBonus("c1", 1000));
    }

    @Test
    void loyaltyBonus_bronzeTier_lowPurchase() {
        assertEquals(8.0, god.calculateLoyaltyBonus("c2", 200));
    }

    @Test
    void loyaltyBonus_silverTier_midPurchase() {
        assertEquals(60.0, god.calculateLoyaltyBonus("c3", 600));
    }

    @Test
    void loyaltyBonus_unknownCustomer_throws() {
        assertThrows(RuntimeException.class, () -> god.calculateLoyaltyBonus("nope", 500));
    }

    // --- calculateShippingFee (tripwire) ---

    @Test
    void shippingFee_goldTier_isFree() {
        assertEquals(0.0, god.calculateShippingFee("c1", 10));
    }

    @Test
    void shippingFee_bronzeTier_isWeighted() {
        assertEquals(15.0, god.calculateShippingFee("c2", 10));
    }

    @Test
    void shippingFee_silverTier_isWeighted() {
        assertEquals(6.0, god.calculateShippingFee("c3", 4));
    }

    @Test
    void shippingFee_unknownCustomer_throws() {
        assertThrows(RuntimeException.class, () -> god.calculateShippingFee("nope", 5));
    }

    // --- applyDiscountCode (tripwire) ---

    @Test
    void discountCode_goldTier_vipCode_isValid() {
        assertTrue(god.applyDiscountCode("c1", "VIP2024"));
    }

    @Test
    void discountCode_bronzeTier_welcomeCode_isValid() {
        assertTrue(god.applyDiscountCode("c2", "WELCOME10"));
    }

    @Test
    void discountCode_silverTier_randomCode_isInvalid() {
        assertFalse(god.applyDiscountCode("c3", "RANDOM"));
    }

    @Test
    void discountCode_bronzeTier_vipCode_isInvalid() {
        assertFalse(god.applyDiscountCode("c2", "VIP2024")); // VIP requires GOLD tier
    }

    @Test
    void discountCode_unknownCustomer_throws() {
        assertThrows(RuntimeException.class, () -> god.applyDiscountCode("nope", "WELCOME10"));
    }

    // --- generateInvoiceSummary (tripwire) ---

    @Test
    void invoiceSummary_knownCustomerAndOrder_formatsCorrectly() {
        assertEquals("c1 | o-small | total: 30.0", god.generateInvoiceSummary("c1", "o-small"));
    }

    @Test
    void invoiceSummary_unknownOrder_throws() {
        assertThrows(RuntimeException.class, () -> god.generateInvoiceSummary("c1", "nope"));
    }

    @Test
    void invoiceSummary_unknownCustomer_throws() {
        assertThrows(RuntimeException.class, () -> god.generateInvoiceSummary("nope", "o-small"));
    }

    // --- processRefund (tripwire; carries the known bug) ---

    @Test
    void processRefund_smallOrder_shouldNotChargeFee_KNOWN_BUG() {
        // Documents a known, pre-existing bug: the fee comparison in
        // processRefund is inverted, so small refunds get penalized instead
        // of large ones. This test asserts the CORRECT behavior and is
        // expected to FAIL right now (actual: 25.0). It must still fail,
        // the same way, after the extraction — fixing it is out of scope
        // for this task and must not happen as a side effect.
        assertEquals(30.0, god.processRefund("c1", "o-small"));
    }

    @Test
    void processRefund_largeOrder_currentBehavior() {
        // Characterization test: pins today's actual behavior for a large
        // refund, not a claim that it's correct.
        assertEquals(200.0, god.processRefund("c1", "o-large"));
    }

    // --- chkShipElig (the flow to extract for the quality axis) ---

    @Test
    void shipElig_zeroWeight_isFalse() {
        assertFalse(god.chkShipElig("c1", "o-large", 0, "IT"));
    }

    @Test
    void shipElig_tooHeavy_isFalse() {
        assertFalse(god.chkShipElig("c1", "o-large", 35, "IT"));
    }

    @Test
    void shipElig_nullCountry_isFalse() {
        assertFalse(god.chkShipElig("c1", "o-large", 10, null));
    }

    @Test
    void shipElig_euCountry_orderAboveThreshold_isTrue() {
        assertTrue(god.chkShipElig("c1", "o-large", 10, "IT"));
    }

    @Test
    void shipElig_euCountry_smallOrder_goldTier_isTrue() {
        assertTrue(god.chkShipElig("c1", "o-tiny", 10, "IT"));
    }

    @Test
    void shipElig_euCountry_smallOrder_nonGoldTier_isFalse() {
        assertFalse(god.chkShipElig("c2", "o-tiny", 10, "IT"));
    }

    @Test
    void shipElig_nonEuCountry_lightWeight_isTrue() {
        assertTrue(god.chkShipElig("c1", "o-large", 3, "US"));
    }

    @Test
    void shipElig_nonEuCountry_heavierWeight_isFalse() {
        assertFalse(god.chkShipElig("c1", "o-large", 10, "US"));
    }

    @Test
    void shipElig_unknownCustomer_throws() {
        assertThrows(RuntimeException.class, () -> god.chkShipElig("nope", "o-large", 10, "IT"));
    }

    @Test
    void shipElig_unknownOrder_throws() {
        assertThrows(RuntimeException.class, () -> god.chkShipElig("c1", "nope", 10, "IT"));
    }
}
