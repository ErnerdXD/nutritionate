import { applicationDefault, cert, getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

function firebaseCredential() {
  const json = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!json) return applicationDefault();
  try {
    return cert(JSON.parse(json));
  } catch (error) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_JSON is invalid JSON", {
      cause: error,
    });
  }
}

function firebaseApp() {
  if (getApps().length > 0) return getApps()[0];
  return initializeApp({
    credential: firebaseCredential(),
    projectId: process.env.FIREBASE_PROJECT_ID,
  });
}

export async function requireFirebaseUser(request, response, next) {
  const localBypass =
    process.env.NODE_ENV !== "production" &&
    process.env.ALLOW_INSECURE_LOCAL === "true";
  if (localBypass) return next();

  const authorization = request.get("Authorization") ?? "";
  const match = authorization.match(/^Bearer\s+(.+)$/i);
  if (!match) return response.status(401).json({ error: "Sign in required" });

  try {
    response.locals.user = await getAuth(firebaseApp()).verifyIdToken(match[1]);
    return next();
  } catch {
    return response.status(401).json({ error: "Sign in required" });
  }
}
