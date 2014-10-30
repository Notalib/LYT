# The main namespace

# Version number guide:
#
# Each version number is on the format <major>.<minor>.<patchlevel>
#
# Where:
#   - major is increased when at least one large and substantial feature,
#     architectural-, API- or UI change has been implemented.
#   - minor is increased when at least one feature has been added.
#   - patchlevel is increased when none of the above applies.
#
# All the above are integers with no upper bound, allowing versions numbers
# like 17.101.4.
#
# Version numbers such as 1.0.0_002 are used to indicate release candidates.
# This indicates release candidate 2 of version 1.0.0, but we do not include
# the release candidate numbers in the version info below.

# TODO: make it possible to keep lyt in a private namespace
#       (see LYT issue #63 for a discussion).

window.LYT =
  VERSION: '2.2.0'
