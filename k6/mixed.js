import http from "k6/http";
import { sleep, check } from "k6";

export const options = {
  vus: 5,
  iterations: 100,
};

const BASE_URL = __ENV.TARGET;

export default function () {
  if (!BASE_URL) throw new Error("TARGET not set");

  const res = http.get(`${BASE_URL}/api/ping`);
  check(res, { "status is 200": (r) => r.status === 200 });

  // randomize delay: some quick hits, some slow ones
  sleep(Math.random() * 5);
}
