const fs = require("fs");

const keymap = fs.readFileSync("./adv360.keymap").toString().split("\n");

const format = (start, lines) => {
  let end;
  for (let i = start; i < lines.length; i++) {
    if (/>;$/.test(lines[i])) {
      end = i;
      break;
    }
  }
};

for (let i = 0; i < keymap.length; i++) {
  const line = keymap[i];
  if (/bindings += +</.test(line)) {
    format(i, keymap);
  }
}
