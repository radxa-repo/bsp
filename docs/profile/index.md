# Understand profile

Profiles are subfolders under `linux` and `u-boot` folder. Each of them describes a specific flavor of their targeted software.

## Special files

* [fork.conf](fork.conf.md): Profile config file
* [kconfig.conf](kconfig.conf.md): kconfig overriding file

## Tree structure and mode of operation

```
sample
├── 0001-common -> ../.common/
├── 0010-backport
│   ├── 0001-scripts-dtc-Update-to-upstream-version-v1.6.0-51-g18.patch
│   ├── 0002-kbuild-Add-support-to-build-overlays-.dtbo.patch.ignore
│   ├── 0003-mm-page_alloc-fix-building-error-on-Werror-array-com.patch
│   └── 0004-etherdevice-Adjust-ether_addr-prototypes-to-silence-.patch
├── 0001-Fix-multiple-definition-of-yylloc.patch
├── 0002-Suppress-additional-warnings.patch
├── fork.conf
├── kconfig.conf
└── rockchip -> ../.rockchip
```
