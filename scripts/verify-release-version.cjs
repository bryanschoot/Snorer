'use strict';

const fs = require('node:fs');
const path = require('node:path');

const tag = process.argv[2] || process.env.RELEASE_TAG;
if (!tag) {
  throw new Error('Pass a release tag, for example: node scripts/verify-release-version.cjs v0.1.0');
}

const match = /^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.exec(tag);
if (!match) {
  throw new Error(`Release tag must use vMAJOR.MINOR.PATCH: ${tag}`);
}

const pubspec = fs.readFileSync(path.join(__dirname, '..', 'pubspec.yaml'), 'utf8');
const versionLine = /^version:\s*([^\s]+)\s*$/m.exec(pubspec);
if (!versionLine) {
  throw new Error('pubspec.yaml does not define a version.');
}

const packageVersion = versionLine[1].split('+', 1)[0];
const tagVersion = tag.slice(1);
if (packageVersion !== tagVersion) {
  throw new Error(`Tag ${tag} does not match pubspec.yaml version ${packageVersion}.`);
}

console.log(`release tag=${tag} version=${packageVersion}`);
