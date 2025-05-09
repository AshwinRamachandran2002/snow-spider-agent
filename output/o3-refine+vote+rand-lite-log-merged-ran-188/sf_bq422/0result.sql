/*-----------------------------------------------------------------------------
  NLST CT – compare average series-size (MiB) for:
    1) Top-3 patients with the largest slice-interval tolerance
    2) Top-3 patients with the largest exposure tolerance
-----------------------------------------------------------------------------*/
WITH images AS (                               /* all NLST-CT instances */
  SELECT
      "PatientID",
      "SeriesInstanceUID",
      "instance_size",

      /* z-coordinate (convert VARIANT → STRING → DOUBLE) */
      TRY_TO_DOUBLE(("ImagePositionPatient"[2])::STRING)             AS z_mm,

      /* exposure value (coalesce the first convertible field) */
      COALESCE(
        TRY_TO_DOUBLE("ExposureInmAs"        ::STRING),
        TRY_TO_DOUBLE("ExposureInuAs"        ::STRING),
        TRY_TO_DOUBLE("Exposure"             ::STRING),
        TRY_TO_DOUBLE("XRayTubeCurrentInmA"  ::STRING),
        TRY_TO_DOUBLE("XRayTubeCurrent"      ::STRING)
      )                                                              AS exposure_val
  FROM IDC.IDC_V17.DICOM_ALL
  WHERE "collection_id" = 'nlst'
    AND "Modality"      = 'CT'
),

/*-------------------- series-level aggregates ------------------------------*/
series_sizes AS (                           /* MiB per series */
  SELECT
      "PatientID",
      "SeriesInstanceUID",
      SUM("instance_size") / 1048576.0      AS series_size_mib
  FROM images
  GROUP BY "PatientID","SeriesInstanceUID"
),

series_slice_stats AS (                     /* min / max Δz per series */
  WITH diffs AS (
    SELECT
        "PatientID",
        "SeriesInstanceUID",
        ABS(z_mm
            - LAG(z_mm) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY z_mm)
        ) AS dz
    FROM images
    WHERE z_mm IS NOT NULL
  )
  SELECT
      "PatientID",
      "SeriesInstanceUID",
      MIN(dz) AS min_dz,
      MAX(dz) AS max_dz
  FROM diffs
  WHERE dz IS NOT NULL
  GROUP BY "PatientID","SeriesInstanceUID"
),

series_exposure_stats AS (                  /* min / max exposure per series */
  SELECT
      "PatientID",
      "SeriesInstanceUID",
      MIN(exposure_val) AS min_exp,
      MAX(exposure_val) AS max_exp
  FROM images
  WHERE exposure_val IS NOT NULL
  GROUP BY "PatientID","SeriesInstanceUID"
),

/*-------------------- patient-level tolerances -----------------------------*/
patient_slice_tolerance AS (
  SELECT
      "PatientID",
      MAX(max_dz) - MIN(min_dz)             AS slice_interval_range_mm
  FROM series_slice_stats
  GROUP BY "PatientID"
),

patient_exposure_tolerance AS (
  SELECT
      "PatientID",
      MAX(max_exp) - MIN(min_exp)           AS exposure_range
  FROM series_exposure_stats
  GROUP BY "PatientID"
),

patient_avg_series_size AS (                /* mean series-size per patient */
  SELECT
      "PatientID",
      AVG(series_size_mib) AS avg_series_size_mib
  FROM series_sizes
  GROUP BY "PatientID"
),

/*-------------------- top-3 cohorts ----------------------------------------*/
top_slice AS (
  SELECT
      s."PatientID",
      a.avg_series_size_mib
  FROM patient_slice_tolerance s
  JOIN patient_avg_series_size a USING ("PatientID")
  ORDER BY s.slice_interval_range_mm DESC NULLS LAST
  LIMIT 3
),

top_exposure AS (
  SELECT
      e."PatientID",
      a.avg_series_size_mib
  FROM patient_exposure_tolerance e
  JOIN patient_avg_series_size   a USING ("PatientID")
  ORDER BY e.exposure_range DESC NULLS LAST
  LIMIT 3
)

/*-------------------- final report -----------------------------------------*/
SELECT 'Top 3 by Slice Interval' AS "Group",
       "PatientID",
       ROUND(avg_series_size_mib,2) AS avg_series_size_mib
FROM   top_slice

UNION ALL

SELECT 'Top 3 by Max Exposure'   AS "Group",
       "PatientID",
       ROUND(avg_series_size_mib,2) AS avg_series_size_mib
FROM   top_exposure;