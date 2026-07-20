/**
 * Help examples shown by the Browser CLI root command.
 */
/** Core Browser CLI examples for lifecycle and inspection commands. */
export const browserCoreExamples = [
  "nova browser status",
  "nova browser start",
  "nova browser start --headless",
  "nova browser stop",
  "nova browser tabs",
  "nova browser open https://example.com",
  "nova browser focus abcd1234",
  "nova browser close abcd1234",
  "nova browser screenshot",
  "nova browser screenshot --full-page",
  "nova browser screenshot --ref 12",
  "nova browser snapshot",
  "nova browser snapshot --format aria --limit 200",
  "nova browser snapshot --efficient",
  "nova browser snapshot --labels",
];

/** Browser CLI examples for interaction/action commands. */
export const browserActionExamples = [
  "nova browser navigate https://example.com",
  "nova browser resize 1280 720",
  "nova browser click 12 --double",
  "nova browser click-coords 120 340",
  'nova browser type 23 "hello" --submit',
  "nova browser press Enter",
  "nova browser hover 44",
  "nova browser drag 10 11",
  "nova browser select 9 OptionA OptionB",
  "nova browser upload /tmp/nova/uploads/file.pdf",
  "nova browser upload media://inbound/file.pdf",
  'nova browser fill --fields \'[{"ref":"1","value":"Ada"}]\'',
  "nova browser dialog --accept",
  'nova browser wait --text "Done"',
  "nova browser evaluate --fn '(el) => el.textContent' --ref 7",
  "nova browser evaluate --fn 'const title = document.title; return title;'",
  "nova browser console --level error",
  "nova browser pdf",
];
