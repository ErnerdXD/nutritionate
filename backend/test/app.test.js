import assert from "node:assert/strict";
import test from "node:test";

import { createApp } from "../src/app.js";

const validRequest = {
  question: "How does one serving fit my lower-sugar goal?",
  goal: "lowerSugar",
  product: {
    barcode: "9556995204554",
    name: "Test wafers",
    brand: "Test brand",
    source: "Verified package label",
    ingredients: "Wheat flour, sugar",
    servingSizeG: 20,
    servingDescription: "1 wafer",
    packageSizeG: 100,
    nutrients: {
      calories: 500,
      fatG: 20,
      saturatedFatG: 10,
      carbohydratesG: 70,
      sugarsG: 30,
      fiberG: 3,
      proteinG: 6,
      saltG: 1,
    },
  },
};

async function withServer(coach, action) {
  process.env.ALLOW_INSECURE_LOCAL = "true";
  const server = createApp({ coach }).listen(0, "127.0.0.1");
  await new Promise((resolve) => server.once("listening", resolve));
  const { port } = server.address();
  try {
    await action(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

test("health endpoint does not expose secrets", async () => {
  await withServer(async () => ({}), async (baseUrl) => {
    const response = await fetch(`${baseUrl}/health`);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), { status: "ok" });
  });
});

test("coach validates input and returns structured output", async () => {
  const coach = async () => ({ answer: "One serving has verified values.", cautions: [] });
  await withServer(coach, async (baseUrl) => {
    const response = await fetch(`${baseUrl}/v1/coach`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(validRequest),
    });
    assert.equal(response.status, 200);
    const body = await response.json();
    assert.equal(body.answer, "One serving has verified values.");
    assert.match(body.disclaimer, /General information/);
  });
});

test("coach rejects oversized or malformed requests without details", async () => {
  await withServer(async () => ({}), async (baseUrl) => {
    const response = await fetch(`${baseUrl}/v1/coach`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ question: "x".repeat(301) }),
    });
    assert.equal(response.status, 400);
    assert.deepEqual(await response.json(), { error: "Invalid request" });
  });
});
