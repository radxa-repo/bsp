# Local development workflow

In this article, we will demonstrate how to develop and create patches for `bsp`.

## Prepare working tree

Use `--no-build` and `-C|--distclean` to set up the source tree with `bsp`
predefined profiles:

```bash
./bsp -C --no-build linux latest
```

## Retrive additional commit history

`bsp` uses shallow clone by default to save bandwidth and speed up build process.
However, you might want to access additional git history for `rebase` or `cherry-pick`.
You can use either of the following 2 options to fetch more commits:

```bash
cd .src/linux
# Fetch HEAD~10 commits
git fetch --depth=10 --all
# Fetch everything
# WARNING! VERY SLOW!
git fetch --unshallow --all
```

## Build packages

You can use `--dirty` to build without resetting the source tree. This will allow the build process to reuse previously built objects:

```bash
./bsp --dirty linux latest
```

## Install build artifacts

You can use `./bsp install` to install the built package to a root partition (like a microSD card):

```bash
./bsp install linux-image-6.*_arm64.deb /dev/sdb2
```

## Create patch set

After you are happy with the changes, you can export your commits with `git format-patch`:

```bash
mkdir -p linux/latest/0500-my-first-pr
cd .src/linux
# Update start-number to the last one + 1
# in your targetting patch subfolder
git format-patch -M -N --start-number 1 --zero-commit -o ../../linux/latest/0500-my-first-pr HEAD~1
```

Move the outputted patch files to the corresponding subfolder, and you are ready to submit your first PR!
