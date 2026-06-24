# Inputs

`results_calib_sorting_hours_A4.mat` is the stationary reference output used to regenerate plots without rerunning the full model.

The main replication script uses this file only when:

```matlab
setenv('HA_IE_REPLICATION_SKIP_MODEL','1')
```

If the full model is run, a new `.mat` is created under:

```text
replication_package/outputs/stationary/replication_calib_sorting_hours_A4/
```
