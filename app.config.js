const packageJson = require('./package.json');
const { androidVersionCode } = require('./scripts/release-version.cjs');

module.exports = ({ config }) => ({
  ...config,
  version: packageJson.version,
  android: {
    ...config.android,
    versionCode: androidVersionCode(packageJson.version),
  },
});
