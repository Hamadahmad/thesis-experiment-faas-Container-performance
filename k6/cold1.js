import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 1,
  iterations: 10,          // 10 cold-ish calls
  maxDuration: "40m",      // give it plenty of time
};

export default function () {
  const target = __ENV.LAMBDA || __ENV.TARGET;
  const res = http.get(`${target}/api/ping`);
  check(res, { "200": (r) => r.status === 200 });
  // wait so Lambda can scale back to 0 / recycle env
  sleep(180); // 3 minutes; change to 60 if you want faster runs
}
