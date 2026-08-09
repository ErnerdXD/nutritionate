import crypto from "node:crypto";

import express from "express";
import { rateLimit } from "express-rate-limit";
import helmet from "helmet";

import { requireFirebaseUser } from "./auth.js";
import { createGeminiCoach } from "./geminiCoach.js";
import { createProductResearch } from "./productResearch.js";
import { coachRequestSchema, productResearchRequestSchema } from "./schemas.js";

export function createApp({ coach, productResearch } = {}) {
  const app = express();
  let resolvedCoach = coach;
  let resolvedProductResearch = productResearch;

  app.disable("x-powered-by");
  app.use(helmet());
  app.use((request, response, next) => {
    response.locals.requestId = crypto.randomUUID();
    response.set("X-Request-Id", response.locals.requestId);
    next();
  });

  app.get("/health", (_request, response) => {
    response.json({ status: "ok" });
  });

  app.post(
    "/v1/coach",
    express.json({ limit: "16kb", strict: true }),
    rateLimit({
      windowMs: 60_000,
      limit: 8,
      standardHeaders: "draft-8",
      legacyHeaders: false,
      message: { error: "Too many requests. Please wait and try again." },
    }),
    requireFirebaseUser,
    async (request, response) => {
      const result = coachRequestSchema.safeParse(request.body);
      if (!result.success) {
        return response.status(400).json({ error: "Invalid request" });
      }

      try {
        resolvedCoach ??= createGeminiCoach();
        const answer = await resolvedCoach(result.data);
        return response.json({
          ...answer,
          disclaimer:
            "General information only. Use the current package label and consult a qualified clinician for medical or allergy decisions.",
        });
      } catch (error) {
        console.error("Coach request failed", {
          requestId: response.locals.requestId,
          name: error?.name,
          message: error?.message,
        });
        if (error?.status === 429 || error?.code === 429) {
          return response.status(429).json({
            error:
              "AI quota reached. Wait for the quota to reset or enable Gemini API billing.",
          });
        }
        if (error?.status === 503 || error?.code === 503) {
          return response.status(503).json({
            error: "The AI service is busy. Please wait a moment and try again.",
          });
        }
        return response.status(502).json({
          error: "The nutrition assistant is temporarily unavailable",
          requestId: response.locals.requestId,
        });
      }
    },
  );

  app.post(
    "/v1/product-research",
    express.json({ limit: "12mb", strict: true }),
    rateLimit({
      windowMs: 60_000,
      limit: 3,
      standardHeaders: "draft-8",
      legacyHeaders: false,
      message: { error: "Too many research requests. Please wait and try again." },
    }),
    requireFirebaseUser,
    async (request, response) => {
      const result = productResearchRequestSchema.safeParse(request.body);
      if (!result.success) {
        return response.status(400).json({ error: "Invalid research request" });
      }
      try {
        resolvedProductResearch ??= createProductResearch();
        return response.json(await resolvedProductResearch(result.data));
      } catch (error) {
        console.error("Product research failed", {
          requestId: response.locals.requestId,
          name: error?.name,
          message: error?.message,
        });
        if (error?.status === 429 || error?.code === 429) {
          return response.status(429).json({
            error:
              "AI research quota reached. Wait for the daily quota to reset or enable Gemini API billing.",
          });
        }
        if (error?.status === 503 || error?.code === 503) {
          return response.status(503).json({
            error: "The AI service is busy. Please wait a moment and try again.",
          });
        }
        return response.status(502).json({
          error: "Product research is temporarily unavailable",
          requestId: response.locals.requestId,
        });
      }
    },
  );

  app.use((_request, response) => {
    response.status(404).json({ error: "Not found" });
  });

  app.use((error, _request, response, _next) => {
    console.error("Unhandled backend error", {
      requestId: response.locals.requestId,
      name: error?.name,
      message: error?.message,
    });
    if (error?.type === "entity.too.large") {
      return response.status(413).json({
        error: "The photos are too large. Retake them closer to the package.",
      });
    }
    if (error instanceof SyntaxError) {
      return response.status(400).json({ error: "Invalid request" });
    }
    response.status(500).json({ error: "Internal server error" });
  });

  return app;
}
