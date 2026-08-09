import assert from "node:assert/strict";
import test from "node:test";

import { generateWithRetry } from "../src/geminiRetry.js";

test("retries transient Gemini failures and then succeeds", async () => {
  let attempts = 0;
  const result = await generateWithRetry(
    async () => {
      attempts += 1;
      if (attempts < 3) throw Object.assign(new Error("busy"), { status: 503 });
      return "ok";
    },
    { delaysMs: [0, 0], sleep: async () => {} },
  );
  assert.equal(result, "ok");
  assert.equal(attempts, 3);
});

test("does not retry permanent Gemini failures", async () => {
  let attempts = 0;
  await assert.rejects(
    generateWithRetry(
      async () => {
        attempts += 1;
        throw Object.assign(new Error("invalid"), { status: 400 });
      },
      { delaysMs: [0], sleep: async () => {} },
    ),
  );
  assert.equal(attempts, 1);
});
