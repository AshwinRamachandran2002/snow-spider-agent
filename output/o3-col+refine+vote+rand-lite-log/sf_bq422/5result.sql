WITH images AS (
  SELECT
    "PatientID",
    "SeriesInstanceUID",
    "SliceThickness",
    "Exposure",
    "instance_size"
  FROM IDC.IDC_V17.DICOM_ALL
  WHERE "collection_id" = 'nlst'
    AND "Modality"      = 'CT'
),
/* --------- series-level size (MiB) --------- */
series_sizes AS (
  SELECT
    "PatientID",
    "SeriesInstanceUID",
    SUM("instance_size")/1048576.0 AS "series_size_mib"
  FROM images
  GROUP BY "PatientID", "SeriesInstanceUID"
),
/* --------- top-3 patients by slice-interval tolerance --------- */
slice_vals AS (
  SELECT DISTINCT
    "PatientID",
    TRY_TO_DOUBLE("SliceThickness") AS slice_mm
  FROM images
  WHERE "SliceThickness" IS NOT NULL
),
slice_tol AS (
  SELECT
    "PatientID",
    MAX(slice_mm) - MIN(slice_mm) AS slice_tol_mm
  FROM slice_vals
  GROUP BY "PatientID"
),
top_slice_patients AS (
  SELECT "PatientID"
  FROM slice_tol
  ORDER BY slice_tol_mm DESC NULLS LAST
  LIMIT 3
),
slice_group_avg AS (
  SELECT
    'Top 3 by Slice Interval' AS group_label,
    AVG("series_size_mib")    AS avg_series_size_mib
  FROM series_sizes
  WHERE "PatientID" IN (SELECT "PatientID" FROM top_slice_patients)
),
/* --------- top-3 patients by exposure difference --------- */
exposure_vals AS (
  SELECT
    "PatientID",
    TRY_TO_DOUBLE("Exposure") AS exposure_mas
  FROM images
  WHERE "Exposure" IS NOT NULL
),
exposure_numeric AS (
  SELECT *
  FROM exposure_vals
  WHERE exposure_mas IS NOT NULL
),
exposure_diff AS (
  SELECT
    "PatientID",
    MAX(exposure_mas) - MIN(exposure_mas) AS exp_diff_mas
  FROM exposure_numeric
  GROUP BY "PatientID"
),
top_exp_patients AS (
  SELECT "PatientID"
  FROM exposure_diff
  ORDER BY exp_diff_mas DESC NULLS LAST
  LIMIT 3
),
exp_group_avg AS (
  SELECT
    'Top 3 by Max Exposure' AS group_label,
    AVG("series_size_mib")  AS avg_series_size_mib
  FROM series_sizes
  WHERE "PatientID" IN (SELECT "PatientID" FROM top_exp_patients)
)
/* --------- final combined output --------- */
SELECT * FROM slice_group_avg
UNION ALL
SELECT * FROM exp_group_avg;