import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 1,
  iterations: 10,
};

export default function () {
  const target = __ENV.LAMBDA || __ENV.TARGET;
  const res = http.get(`${target}/api/ping`);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(30);  // 30s between calls -> whole run ~5 min
}
