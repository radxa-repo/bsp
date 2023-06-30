# Reproduce a previous release

In this example, we will recreate `linux-rockchip` 5.10.110-5 package.

1. Find the original GitHub release for the desired package  
   For our example, it is located at [https://github.com/radxa-pkg/linux-rockchip/releases/tag/5.10.110-5](https://github.com/radxa-pkg/linux-rockchip/releases/tag/5.10.110-5).

2. From the release pages, you will see multiple packages.  
   We will focus on the top 2 packages:

| File Name                                                        | Size   |
|------------------------------------------------------------------|--------|
| linux-headers-5.10.110-5-rockchip_5.10.110-5-1932709cf_arm64.deb | 7.4 MB |
| linux-headers-radxa-nx5-io_5.10.110-5-3a557f6_all.deb            | 1.1 KB |

3. As our packages are built with `bsp` and `radxa/kernel`, there are 2 git commits that we need to find out to accurately reproduce those packages:  
   Since the real package (the one with larger file size) is closely related to `radxa/kernel`, `1932709cf` is the commit for it.  
   Since the meta package (the one with smaller file size) is closely related to `bsp`, `3a557f6` is the commit for it.

4. We now have the following essential commit information:  
   `radxa/kernel`: [`1932709cf`](https://github.com/radxa/kernel/commit/1932709cf)  
   `bsp`: [`3a557f6`](https://github.com/radxa-repo/bsp/commit/3a557f6)

5. However, `fork.conf` only takes full commit hash. So click the `radxa/kernel` link above, and click `Browse files` button on GitHub page, that will get you the full commit hash in the URL bar:
   `radxa/kernel`: [`1932709cf7d98d0d92952bba38d990d938fabc58`](https://github.com/radxa/kernel/tree/1932709cf7d98d0d92952bba38d990d938fabc58)  

6. We can also check the content of [`overlay.sh`](https://github.com/radxa-repo/bsp/blob/3a557f688241ba03dba26f6804d1f39564342856/linux/.common/overlays.sh) to find the commit used for `radxa/overlays`:  
   `radxa/overlays`: [`4940ae33e4def0fb9133faf68adf0c3421b61f06`](https://github.com/radxa/overlays/commit/4940ae33e4def0fb9133faf68adf0c3421b61f06)

7. We can now recreate the package:

```bash
git clone --recurse-submodules https://github.com/radxa-repo/bsp.git
cd bsp
# switch to bsp commit found above
git switch --detach 3a557f6
# replace BSP_BRANCH with radxa/kernel commit found above
sed -i "s/BSP_BRANCH.*/BSP_COMMIT='1932709cf7d98d0d92952bba38d990d938fabc58'/" linux/rockchip/fork.conf
./bsp linux rockchip
# the prepared kernel tree will be available under .src/linux
```
