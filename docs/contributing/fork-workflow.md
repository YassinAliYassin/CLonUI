# Contributing from a Fork

Use this workflow when you do not have write access to the upstream repository. Keep each pull request limited to one feature or bug fix, as required by the main contributing guide.

## 1. Fork and clone

Fork the repository on GitHub, then clone your fork. Replace `YOUR_GITHUB_USERNAME` with your GitHub username.

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/CLonUI.git
cd CLonUI
git remote add upstream https://github.com/SolidAI/CLonUI.git
git remote -v
```

The `origin` remote should point to your fork. The `upstream` remote should point to the canonical repository.

## 2. Create a focused branch

Start from the latest upstream default branch before making changes.

```bash
git fetch upstream
git switch main
git pull --ff-only upstream main
git switch -c fix/short-description
```

Choose a branch name that describes the single change. Use a `feat/`, `fix/`, `docs/`, or other suitable prefix.

## 3. Install and verify

Follow the prerequisites and setup steps in [the development guide](development.md). Before submitting, run the checks that apply to your changes as documented in [CONTRIBUTING.md](../../CONTRIBUTING.md). Do not claim a check passed unless you ran it successfully.

## 4. Commit and push to your fork

Use the Conventional Commit format required by the project.

```bash
git add path/to/changed-file
git commit -m "docs(scope): describe the change"
git push -u origin HEAD
```

Replace the example commit message with one that accurately describes your change. Do not include generated signatures or claim platform verification you have not performed.

## 5. Open a pull request

Open a pull request from your fork's branch into the upstream `main` branch. Use the repository's pull request template, explain the problem and solution, list the checks you actually ran, and keep the PR limited to one independently reviewable change.

## 6. Keep your branch current

If upstream `main` advances before review, update your local branch carefully:

```bash
git fetch upstream
git switch main
git pull --ff-only upstream main
git switch fix/short-description
git rebase main
git push --force-with-lease
```

Only rebase a branch you own and coordinate first if anyone else is using it. If conflicts occur, resolve them deliberately and rerun the relevant checks.
