/*--------------------------------------------------------------------
  NLST CT – average series size (MiB) for:
  1)  top-3 patients by slice-interval range
  2)  top-3 patients by exposure-value range
--------------------------------------------------------------------*/
WITH ct_images AS (               /* NLST CT instances only              */
  SELECT
      "PatientID",
      "SeriesInstanceUID",
      "instance_size",
      TRY_TO_NUMBER("SpacingBetweenSlices")          AS slice_interval,  -- text → number
      CAST("ExposureInmAs" AS FLOAT)                 AS exposure         -- already numeric
  FROM IDC.IDC_V17.DICOM_ALL
  WHERE "collection_name" = 'NLST'
    AND "Modality"         = 'CT'
),
/* per-series totals & single representative interval / exposure value  */
series_stats AS (
  SELECT
      "PatientID",
      "SeriesInstanceUID",
      SUM("instance_size")/(1024*1024)               AS series_size_mib,
      MIN(slice_interval)                            AS series_slice_interval,
      MIN(exposure)                                  AS series_exposure
  FROM ct_images
  GROUP BY "PatientID", "SeriesInstanceUID"
),
/* per-patient tolerance metrics and mean series size                   */
patient_stats AS (
  SELECT
      "PatientID",
      MAX(series_slice_interval) - MIN(series_slice_interval)  AS slice_interval_diff,
      MAX(series_exposure)       - MIN(series_exposure)        AS exposure_diff,
      AVG(series_size_mib)                                    AS avg_series_size_mib
  FROM series_stats
  GROUP BY "PatientID"
),
/* top-3 patients by each metric                                        */
top3_by_slice AS (
  SELECT  avg_series_size_mib
  FROM    patient_stats
  WHERE   slice_interval_diff IS NOT NULL
  ORDER BY slice_interval_diff DESC NULLS LAST
  LIMIT 3
),
top3_by_exposure AS (
  SELECT  avg_series_size_mib
  FROM    patient_stats
  WHERE   exposure_diff IS NOT NULL
  ORDER BY exposure_diff DESC NULLS LAST
  LIMIT 3
),
/* average of the mean-series-sizes for those top-3 sets                */
agg_slice AS (
  SELECT 'Top 3 by Slice Interval' AS "Group",
         AVG(avg_series_size_mib)  AS avg_series_size_mib
  FROM   top3_by_slice
),
agg_exposure AS (
  SELECT 'Top 3 by Max Exposure'   AS "Group",
         AVG(avg_series_size_mib)  AS avg_series_size_mib
  FROM   top3_by_exposure
)

SELECT * FROM agg_slice
UNION ALL
SELECT * FROM agg_exposure;