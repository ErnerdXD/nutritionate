const transientStatuses = new Set([408, 500, 502, 503, 504]);

function errorStatus(error) {
  const value = error?.status ?? error?.code;
  return typeof value === "number" ? value : Number.parseInt(value, 10);
}

export async function generateWithRetry(generate, {
  delaysMs = [750, 1_750, 3_500],
  sleep = (delay) => new Promise((resolve) => setTimeout(resolve, delay)),
} = {}) {
  for (let attempt = 0; ; attempt += 1) {
    try {
      return await generate();
    } catch (error) {
      if (!transientStatuses.has(errorStatus(error)) || attempt >= delaysMs.length) {
        throw error;
      }
      const jitter = Math.floor(Math.random() * 250);
      await sleep(delaysMs[attempt] + jitter);
    }
  }
}
