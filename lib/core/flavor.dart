/// Build-time flavor injected via `--dart-define-from-file=flavors/beta.json` or `prod.json`.
/// Default is always beta — nothing ships to prod without an explicit prod build.
const kFlavor = String.fromEnvironment('FLAVOR', defaultValue: 'beta');
const kAppDisplayName = String.fromEnvironment('APP_DISPLAY_NAME', defaultValue: 'Cobalt Beta');
const kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://cobalt-staging.eba-2efgir7w.eu-west-3.elasticbeanstalk.com',
);

const kIsBeta = kFlavor == 'beta';
const kIsProd = kFlavor == 'prod';
