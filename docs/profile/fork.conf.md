# fork.conf

`fork.conf` is the profile configuration file. This file is mandatory and is sourced early by `bsp`.

`BSP_GIT` defines upstream source repo.

`BSP_COMMIT` or `BSP_BRANCH` or `BSP_TAG` defines the exact source code. The first defined option in the listed order will be used.

`BSP_DEFCONFIG` defines the defconfig used for building. Default to `defconfig`.

`SUPPORTED_BOARDS` defines the supported product list, which is a [Bash array](https://www.gnu.org/software/bash/manual/html_node/Arrays.html). `bsp` will use this list to create virtual packages that reference the binary package. Suffixes are commonly used to denote kernel/firmware variants that also support the same board. However, the default package is the one that matches exactly to the product name.
