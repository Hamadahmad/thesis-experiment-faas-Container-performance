import http from "k6/http";
import { sleep, check } from "k6";

export const options = {
  vus: __ENV.VUS ? parseInt(__ENV.VUS) : 10,
  iterations: __ENV.ITERS ? parseInt(__ENV.ITERS) : 150,
};

const BASE_URL = __ENV.TARGET;  // set to the *compute* URLs below
const N = __ENV.N ? parseInt(__ENV.N) : 1500;
const REPEATS = __ENV.REPEATS ? parseInt(__ENV.REPEATS) : 1;

export default function () {
  if (!BASE_URL) throw new Error("TARGET not set");
  const res = http.get(`${BASE_URL}/api/compute?n=${N}&repeats=${REPEATS}`);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(1);
}
