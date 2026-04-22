# Releasing to RubyGems

## Use this tree as its own Git repository

While developing inside a larger app, this folder may live under `public_gem/neuron_ai_chatbot/` with no `.git` here.

To publish publicly:

1. Copy this directory to a new path (or use `git subtree split`) so it is the **repository root**.
2. `cd` into that root and run `git init`, `git add -A`, `git commit`, add `origin`, push to GitHub (or GitLab).
3. Bump `lib/neuron_ai_chatbot/version.rb` and add a section to `CHANGELOG.md`.
4. `bundle install && bundle exec rake build`
5. `gem push pkg/neuron_ai_chatbot-X.Y.Z.gem` (RubyGems MFA required; see gemspec metadata).
6. Tag: `git tag vX.Y.Z && git push origin vX.Y.Z`

Replace placeholder GitHub URLs in `neuron_ai_chatbot.gemspec` and badges in `README.md` with your real org/repo before the first push.
