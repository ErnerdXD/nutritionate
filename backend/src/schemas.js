import { z } from "zod";

const boundedNumber = z.number().finite().min(0).max(100000).nullable().optional();

export const coachRequestSchema = z.object({
  question: z
    .string()
    .trim()
    .min(1)
    .max(300)
    .regex(/^[^\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]*$/),
  goal: z.enum([
    "balanced",
    "lowerSugar",
    "higherProtein",
    "lowerSalt",
    "weightAwareness",
  ]),
  recentConversation: z
    .array(
      z.object({
        role: z.enum(["user", "assistant"]),
        text: z.string().trim().min(1).max(600),
      }),
    )
    .max(6)
    .optional(),
  userProfile: z
    .object({
      age: z.number().int().min(13).max(120).nullable(),
      weightKg: z.number().min(20).max(400).nullable(),
      heightCm: z.number().min(80).max(250).nullable(),
      dietaryPattern: z.string().trim().max(80),
      allergens: z.array(z.string().trim().max(40)).max(12),
      priorities: z.array(z.string().trim().max(40)).max(10),
      servingBasis: z.string().trim().max(40),
    })
    .optional(),
  product: z.object({
    barcode: z.string().regex(/^\d{8,14}$/),
    name: z.string().trim().min(1).max(160),
    brand: z.string().trim().max(120),
    source: z.string().trim().max(80),
    ingredients: z.string().trim().max(3000),
    servingSizeG: boundedNumber,
    servingDescription: z.string().trim().max(100).nullable().optional(),
    packageSizeG: boundedNumber,
    nutrients: z.object({
      calories: boundedNumber,
      fatG: boundedNumber,
      saturatedFatG: boundedNumber,
      carbohydratesG: boundedNumber,
      sugarsG: boundedNumber,
      fiberG: boundedNumber,
      proteinG: boundedNumber,
      saltG: boundedNumber,
    }),
  }).optional(),
});

export const coachResponseSchema = z.object({
  answer: z.string().trim().min(1).max(900),
  cautions: z.array(z.string().trim().min(1).max(200)).max(2),
});

export const productResearchRequestSchema = z.object({
  barcode: z.string().regex(/^\d{8,14}$/),
  images: z
    .array(
      z.object({
        mimeType: z.enum(["image/jpeg", "image/png"]),
        data: z.string().min(100).max(4_000_000).regex(/^[A-Za-z0-9+/=]+$/),
      }),
    )
    .min(1)
    .max(3),
});

export const productResearchResponseSchema = z.object({
  eligibleForPrefill: z.boolean(),
  rejectionReason: z.string().trim().max(300),
  exactBarcodeMatch: z.boolean(),
  confidence: z.enum(["low", "medium", "high"]),
  productName: z.string().trim().max(160),
  brand: z.string().trim().max(120),
  packagingDescription: z.string().trim().max(300),
  ingredients: z.string().trim().max(3000),
  servingSizeG: boundedNumber,
  servingDescription: z.string().trim().max(100).nullable().optional(),
  packageSizeG: boundedNumber,
  valuesPer100g: z.boolean(),
  nutrients: z.object({
    calories: boundedNumber,
    fatG: boundedNumber,
    saturatedFatG: boundedNumber,
    carbohydratesG: boundedNumber,
    sugarsG: boundedNumber,
    fiberG: boundedNumber,
    proteinG: boundedNumber,
    sodiumMg: boundedNumber,
  }),
  warnings: z.array(z.string().trim().min(1).max(240)).max(5),
});
