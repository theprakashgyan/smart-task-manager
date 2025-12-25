// logic.test.js
const { classifyTask } = require("./logic");

describe("Auto-Classification Logic", () => {
  // Verify Scheduling & High Priority
  test("correctly identifies scheduling category and high priority", () => {
    const result = classifyTask("Schedule urgent meeting with client");
    expect(result.category).toBe("scheduling");
    expect(result.priority).toBe("high");
  });

  // Verify Technical Category
  test('correctly identifies technical category based on "bug"', () => {
    const result = classifyTask("Fix bug in the login page");
    expect(result.category).toBe("technical");
    expect(result.suggested_actions).toContain("Diagnose issue");
  });

  // Verify Finance Category
  test('correctly identifies finance category based on "invoice"', () => {
    const result = classifyTask("Submit invoice for payment");
    expect(result.category).toBe("finance");
  });

  // Verify Default Fallback
  test("defaults to general and low priority for unknown text", () => {
    const result = classifyTask("Buy milk");
    expect(result.category).toBe("general");
    expect(result.priority).toBe("low");
  });
});
