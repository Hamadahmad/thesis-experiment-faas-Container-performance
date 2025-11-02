import http from "k6/http";
import { sleep, check } from "k6";

export const options = {
  vus: 10,
  iterations: 150, // total requests
};

const BASE_URL = __ENV.TARGET;

export default function () {
  if (!BASE_URL) throw new Error("TARGET not set");

  const res = http.get(`${BASE_URL}/api/ping`);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(1); // short delay between requests
}