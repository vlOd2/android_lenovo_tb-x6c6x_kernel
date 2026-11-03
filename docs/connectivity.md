# Mediatek Connectivity

In this driver there are two separate init flows:

1. `wmt_loader` ioctls (`/dev/wmtdetect`): `CONNSYS_SOC_HW_INIT` -> `wmt_plat_consys_hw_init()` -> `mtk_wcn_consys_hw_init()`. This registers the mtk_wmt platform driver, which makes `mtk_wmt_probe()` run. The probe is what fills in these globals:
- `wmt_consys_ic_ops` = the MT6765 function table (consys_ic_ops_mt6765)
- `gConEmiPhyBase/size` = CONNSYS EMI memory
- regulators, clocks, pinctrl, etc.

2. `DO_MODULE_INIT` -> `do_connectivity_driver_init()` -> WMT init, `/dev/stpwmt`, WLAN init, `/dev/wmtWif`i.
There is no module_init/device_initcall that calls `wmt_plat_consys_hw_init()`. It is only reachable through that loader ioctl. With the stock modules this is fine because wmt_loader always drives the full sequence. In a built-in setup, flow #2 runs but the CONNSYS ioctl effectively doesn't, so:
- `wmt_consys_ic_ops` == NULL
- `gConEmiPhyBase` == 0
- yet `/dev/wmtWifi` exists, so echo 1 > `/dev/wmtWifi` can proceed, but will crash


# Why built in crashes

When wlan_assistant/the WLAN power-on runs, `mtk_wcn_consys_hw_pwr_on()` will bail out because EMI isn't ready, the chip will never come up, and WMT command waits will time out. The timeout path will then call `mtk_wcn_consys_cmd_pre_rx_timeout_dump()`, which does `wmt_consys_ic_ops->consys_ic_cmd_pre_rx_timeout_dump` without a NULL check -> NULL dereference panic.


# What was changed

## `conn_drv_init.c`
- in built-in mode, call `wmt_plat_consys_hw_init()` directly at the start of `do_connectivity_driver_init()`, before WMT/WLAN init i.e no longer relies on the loader ioctl

## `mtk_wcn_consys_hw_init()`
- return immediately if the driver was already probed (so a loader call plus the built-in call don't double-register/register PMIC twice)

- make the `g_probe_called` wait a fixed amount instead of looping forever

- returns an error on probe timeout/registration failure instead of falling through and dereferencing `wmt_consys_ic_ops`

- unregister the driver on timeout

- If hw init fails, `do_connectivity_driver_init()` aborts before creating the half-initialized WMT/WLAN state, so there is nothing to panic later

- Added `NULL` guards in `mtk_wmt_remove()` and `mtk_wcn_consys_hw_deinit()`