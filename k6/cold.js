
import http from "k6/http";
import { sleep } from "k6";

export const options = { vus: 1, iterations: 10 };
const LAMBDA = __ENV.LAMBDA;

export default function () {
  http.get(LAMBDA + "/api/ping");
  sleep(15 * 60);
}
