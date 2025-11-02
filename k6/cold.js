import http from "k6/http";
import { sleep, check } from "k6";

// 10 iterations, 1 VU, so we can space them out to trigger cold-ish behavior
export const options = {
  vus: 1,
  iterations: 10,
};

const BASE_URL = __ENV.TARGET; // runner passes

export default function () {
  if (!BASE_URL) {
    // fail loudly so you see it
    throw new Error("TARGET env var is not set. Run with: k6 run -e TARGET=<url> k6/cold.js");
  }

  const res = http.get(`${BASE_URL}/api/ping`);
  check(res, {
    "status is 200": (r) => r.status === 200,
  });

  // sleep long enough to let the platform cool down a bit
  // adjust if you want a colder run
  sleep(5);
}
