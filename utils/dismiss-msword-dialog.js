import { exec } from "child_process";

export const dismissMSWordDialog = () => {
  const appleScript = `
      tell application "System Events"
        tell process "Microsoft Word"
          repeat while exists (windows where name contains "Warning")
            click button "OK" of first window where name contains "Warning"
            delay 1.5 -- Adjust the delay as needed
          end repeat
        end tell
      end tell
    `;

  exec(`osascript -e '${appleScript}'`, (err, stdout, stderr) => {
    if (err) {
      console.error("Error executing AppleScript:", stderr);
    } else {
      console.log("Dialog dismissed if it existed");
    }
  });
};
