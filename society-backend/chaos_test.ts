import { ProviderService } from "./src/services/ai/ProviderService";
import { logger } from "./src/shared/Logger";

async function chaosTest() {
  console.log("\n🔥 --- AI V3.2 CHAOS TESTING (CIRCUIT BREAKER) --- 🔥\n");
  const provider = ProviderService.getInstance();
  const providerId = "groq";

  console.log(`Checking initial status for ${providerId}...`);
  const initial = await (provider as any).isAvailable(providerId);
  console.log(`Available: ${initial}`);

  console.log(`\nSimulating ${providerId} failures (3 reported failures)...`);
  await (provider as any).reportFailure(providerId);
  await (provider as any).reportFailure(providerId);
  await (provider as any).reportFailure(providerId);

  console.log("\nChecking status after failure threshold...");
  const after = await (provider as any).isAvailable(providerId);
  
  if (!after) {
    console.log(`✅ PASSED: Circuit Breaker TRIPPED for ${providerId}. Provider is now disabled.`);
  } else {
    console.log(`❌ FAILED: Circuit Breaker did NOT trip for ${providerId}.`);
  }

  console.log("\nTesting fallback behavior during outage...");
  try {
    const context = { requestId: "chaos_123", userId: "u123", societyId: "soc123" };
    const model = await provider.getRouteModel("RETRIEVAL", context);
    console.log("✅ PASSED: Gateway dynamically routed to next available provider.");
  } catch (err: any) {
    console.log(`❌ FAILED: Gateway failed during provider outage: ${err.message}`);
  }

  console.log("\n--- CHAOS TEST COMPLETE ---\n");
}

chaosTest();
