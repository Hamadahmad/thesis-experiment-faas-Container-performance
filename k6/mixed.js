
import http from "k6/http";
import { sleep } from "k6";

export const options = { vus: 5, iterations: 150 };
const TARGET = __ENV.TARGET;

export default function () {
  http.get(TARGET + "/api/ping");
  if (Math.random() < 0.1) sleep(120);
  else sleep(0.1);
}
