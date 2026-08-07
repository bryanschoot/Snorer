'use strict';

const fs = require('node:fs');
const path = require('node:path');
const {
  androidVersionCode,
  parseReleaseTag,
} = require('./release-version.cjs');

const releaseTag = process.argv[2] || process.env.RELEASE_TAG;
if (!releaseTag) {
  throw new Error('Pass a release tag, for example: npm run release:check -- v1.0.0');
}

const packageJson = JSON.parse(
  fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf8')
);
const tagVersion = parseReleaseTag(releaseTag);

if (packageJson.version !== tagVersion.version) {
  throw new Error(
    `Release tag ${releaseTag} does not match package.json version ${packageJson.version}`
  );
}

const versionCode = androidVersionCode(packageJson.version);
console.log(`tag=${releaseTag}`);
console.log(`version=${packageJson.version}`);
console.log(`versionCode=${versionCode}`);
