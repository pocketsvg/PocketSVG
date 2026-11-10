#!/usr/bin/env bash
set -euo pipefail

repo_dir=$(cd "$(dirname "$0")/.." && pwd)
sdk_dir=$(xcrun --sdk macosx --show-sdk-path)
report_dir=$(mktemp -d)
trap 'rm -rf "$report_dir"' EXIT

# Exercise the public ownership contract from Objective-C callers. The fixture
# checks both correct releases/transfers and an expected leak as a positive control.
xcrun clang --analyze \
    -fobjc-arc -fblocks -isysroot "$sdk_dir" \
    -I "$repo_dir/Sources/include" -I "$sdk_dir/usr/include/libxml2" \
    -Xclang -verify \
    -Xanalyzer -analyzer-checker=osx.cocoa.RetainCount \
    -o "$report_dir/callers.plist" \
    "$repo_dir/ci/fixtures/path_ownership.m"

# Prove this check catches a lost annotation, using a temporary shadow header.
# The working tree and production sources remain unchanged.
mkdir "$report_dir/unannotated"
python3 - "$repo_dir/Sources/include/SVGEngine.h" "$report_dir/unannotated/SVGEngine.h" <<'PY_MUTATION'
from pathlib import Path
import sys

header = Path(sys.argv[1]).read_text()
retained = 'CGPathRef CGPathFromSVGPathString(NSString *svgString) CF_RETURNS_RETAINED;'
assert header.count(retained) == 1
Path(sys.argv[2]).write_text(header.replace(retained, retained.replace(' CF_RETURNS_RETAINED', '')))
PY_MUTATION
if xcrun clang --analyze \
    -fobjc-arc -fblocks -isysroot "$sdk_dir" \
    -I "$report_dir/unannotated" -I "$repo_dir/Sources/include" -I "$sdk_dir/usr/include/libxml2" \
    -Xclang -verify \
    -Xanalyzer -analyzer-checker=osx.cocoa.RetainCount \
    -o "$report_dir/unannotated.plist" \
    "$repo_dir/ci/fixtures/path_ownership.m" > "$report_dir/negative-control.log" 2>&1; then
    echo 'Ownership check failed to detect a missing retained-return annotation' >&2
    exit 1
fi
echo 'Negative control: removing CF_RETURNS_RETAINED fails the ownership check as expected'

# Check the real implementation too. Existing unrelated analyzer findings should
# not hide or block this focused ownership regression check.
xcrun clang++ --analyze \
    -std=c++14 -fobjc-arc -fblocks -isysroot "$sdk_dir" \
    -I "$repo_dir/Sources/include" -I "$sdk_dir/usr/include/libxml2" \
    -Xanalyzer -analyzer-checker=osx.cocoa.RetainCount \
    -Xanalyzer -analyzer-output=plist \
    -o "$report_dir/engine.plist" \
    "$repo_dir/Sources/SVGEngine.mm"

python3 - "$report_dir/engine.plist" <<'PY'
import plistlib
import sys

with open(sys.argv[1], 'rb') as report_file:
    diagnostics = plistlib.load(report_file)['diagnostics']
findings = [d for d in diagnostics if 'CGPathFromSVGPathString' in d.get('issue_context', '')]
for finding in findings:
    print(finding['description'], file=sys.stderr)
if findings:
    sys.exit(1)
print('CGPathFromSVGPathString: retained-return analyzer checks passed')
PY
