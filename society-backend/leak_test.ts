import { AIGuardrailsService } from "./src/services/ai/AIGuardrailsService";
import { logger } from "./src/shared/Logger";

async function leakTest() {
  console.log("\n🧪 --- AI MULTI-TENANCY LEAK TEST --- 🧪\n");
  const guardrails = AIGuardrailsService.getInstance();
  const requestId = "test_leak_123";

  // Case 1: Filtering mixed data
  const mixedData = [
    { id: 1, content: "SOCIETY A DATA", society_id: "soc_A" },
    { id: 2, content: "SOCIETY B DATA", society_id: "soc_B" },
    { id: 3, content: "SOCIETY A DATA 2", metadata: { society_id: "soc_A" } }
  ];

  console.log("Testing Case: Filter Society A data from mixed results...");
  const filteredA = guardrails.enforceMultiTenancy(mixedData, "soc_A");
  
  if (filteredA.length === 2 && filteredA.every((i:any) => i.society_id === "soc_A" || i.metadata?.society_id === "soc_A")) {
    console.log("✅ PASSED: Mixed data filtered correctly.");
  } else {
    console.log("❌ FAILED: Leak detected or filtering failed.");
  }

  // Case 2: Multi-tenancy Access Violation
  console.log("\nTesting Case: Directly Accessing Society B data as Society A...");
  try {
    guardrails.enforceMultiTenancy({ society_id: "soc_B" }, "soc_A");
    console.log("❌ FAILED: Access to Society B was NOT denied for Society A.");
  } catch (err: any) {
    console.log(`✅ PASSED: Access denied as expected: ${err.message}`);
  }

  console.log("\n--- LEAK TEST COMPLETE ---\n");
}

leakTest();
