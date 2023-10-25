# Reproduce a previous release

In this example, we will recreate `linux-rockchip` [5.10.110-5](https://github.com/radxa-pkg/linux-rockchip/releases/tag/5.10.110-5) release.

1. Follow [Build artifacts](artifacts.md) section, We now have the following essential commit information at the release build time:  
   `radxa/kernel`: [`1932709cf`](https://github.com/radxa/kernel/commit/1932709cf)  
   `bsp`: [`3a557f6`](https://github.com/radxa-repo/bsp/commit/3a557f6)

2. However, `fork.conf` only takes full commit hash. So click the `radxa/kernel` link above, and click `Browse files` button on GitHub page, that will get you the full commit hash in the URL bar:
   `radxa/kernel`: [`1932709cf7d98d0d92952bba38d990d938fabc58`](https://github.com/radxa/kernel/tree/1932709cf7d98d0d92952bba38d990d938fabc58)  

3. We can also check the content of [`overlay.sh`](https://github.com/radxa-repo/bsp/blob/3a557f688241ba03dba26f6804d1f39564342856/linux/.common/overlays.sh) to find the commit used for `radxa/overlays`:  
   `radxa/overlays`: [`4940ae33e4def0fb9133faf68adf0c3421b61f06`](https://github.com/radxa/overlays/commit/4940ae33e4def0fb9133faf68adf0c3421b61f06)

4. We can now recreate the package:

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
