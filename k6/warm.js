
import http from "k6/http";
import { check, sleep } from "k6";

export const options = { vus: 10, iterations: 150 };
const TARGET = __ENV.TARGET;

export default function () {
  const r = http.get(TARGET + "/api/ping");
  check(r, { "status is 200": (res) => res.status === 200 });
  sleep(0.05);
}
