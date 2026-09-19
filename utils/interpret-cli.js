import { interpret } from "./interpret.js";

const args = process.argv.slice(2);
const index = args.indexOf("--request");
const request = index === -1 ? "" : (args[index + 1] ?? "");
const result = interpret(request);

process.stdout.write(
  `${JSON.stringify({
    ok: result.ok,
    reading: result.reading,
    kind: result.kind,
    message: result.message,
  })}\n`
);
