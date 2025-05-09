/* -------------------------------------------------------------------------
   Average series size (MiB) for:
   1) Top-3 patients with the largest slice–interval spread
   2) Top-3 patients with the largest exposure (mAs) spread
   on NLST CT data
---------------------------------------------------------------------------*/
WITH nlst_ct AS (  --  CT instances from NLST
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        TRY_CAST("SliceThickness" AS FLOAT)          AS slice_thk,
        "ExposureInmAs"                              AS exposure_mAs,
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_name" = 'NLST'
      AND "Modality"        = 'CT'
),
series_sizes AS (   -- size (MiB) + one value of slice/exposure per series
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        SUM("instance_size")/POWER(1024,2)                   AS series_size_mib,
        MIN(slice_thk)   AS slice_thk,       -- any non-NULL value in series
        MIN(exposure_mAs) AS exposure_mAs
    FROM nlst_ct
    GROUP BY "PatientID", "SeriesInstanceUID"
),
patient_spreads AS (   -- per-patient spread of slice interval & exposure
    SELECT
        "PatientID",
        MAX(slice_thk)   - MIN(slice_thk)     AS slice_interval_diff,
        MAX(exposure_mAs)- MIN(exposure_mAs)  AS exposure_diff
    FROM series_sizes
    WHERE slice_thk     IS NOT NULL
       OR exposure_mAs  IS NOT NULL
    GROUP BY "PatientID"
),
top_slice_patients AS (  -- top-3 by slice interval spread
    SELECT "PatientID"
    FROM patient_spreads
    ORDER BY slice_interval_diff DESC NULLS LAST
    LIMIT 3
),
top_exposure_patients AS ( -- top-3 by exposure spread
    SELECT "PatientID"
    FROM patient_spreads
    ORDER BY exposure_diff DESC NULLS LAST
    LIMIT 3
),
avg_series_size_slice AS ( -- average series size for slice-spread winners
    SELECT
        'Top 3 by Slice Interval' AS category,
        AVG(series_size_mib)      AS avg_series_size_mib
    FROM series_sizes
    WHERE "PatientID" IN (SELECT "PatientID" FROM top_slice_patients)
),
avg_series_size_exposure AS ( -- average series size for exposure-spread winners
    SELECT
        'Top 3 by Max Exposure'   AS category,
        AVG(series_size_mib)      AS avg_series_size_mib
    FROM series_sizes
    WHERE "PatientID" IN (SELECT "PatientID" FROM top_exposure_patients)
)
-- final two-row result
SELECT * FROM avg_series_size_slice
UNION ALL
SELECT * FROM avg_series_size_exposure;