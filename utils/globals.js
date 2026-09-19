export { gerundRegex } from "./gerunds.js";

import { gerundRegex } from "./gerunds.js";

// A new expression each time, so callers cannot trip over lastIndex.
export const REGEX = {
  get gerundRegex() {
    return new RegExp(gerundRegex.source, "giu");
  },
};
