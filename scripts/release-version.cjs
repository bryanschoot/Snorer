'use strict';

const STABLE_SEMVER = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;
const ANDROID_VERSION_CODE_LIMIT = 2_100_000_000;

function parseStableVersion(version) {
  const match = STABLE_SEMVER.exec(version);
  if (!match) {
    throw new Error(
      `Version must use stable semantic versioning (MAJOR.MINOR.PATCH): ${version}`
    );
  }

  const [, major, minor, patch] = match;
  return {
    version,
    major: Number(major),
    minor: Number(minor),
    patch: Number(patch),
  };
}

function parseReleaseTag(tag) {
  if (typeof tag !== 'string' || !tag.startsWith('v')) {
    throw new Error(`Release tag must start with v: ${tag || '(missing)'}`);
  }

  return parseStableVersion(tag.slice(1));
}

function androidVersionCode(version) {
  const { major, minor, patch } = parseStableVersion(version);
  const versionCode = major * 1_000_000 + minor * 1_000 + patch;

  if (
    !Number.isSafeInteger(versionCode) ||
    versionCode < 1 ||
    versionCode > ANDROID_VERSION_CODE_LIMIT
  ) {
    throw new Error(`Version is outside the Android versionCode range: ${version}`);
  }

  return versionCode;
}

module.exports = {
  androidVersionCode,
  parseReleaseTag,
  parseStableVersion,
};
