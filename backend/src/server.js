import { createApp } from "./app.js";

const port = Number.parseInt(process.env.PORT ?? "8787", 10);
const host = process.env.HOST ?? "0.0.0.0";

createApp().listen(port, host, () => {
  console.log(`Nutritionate backend listening on http://${host}:${port}`);
});
