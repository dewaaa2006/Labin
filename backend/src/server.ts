import { app } from './app.js';
import { env } from './utils/env.js';

app.listen(env.port, () => {
  console.log(`Labin API running on http://localhost:${env.port}`);
});
