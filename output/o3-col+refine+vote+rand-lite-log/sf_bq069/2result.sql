/* -------------------------------------------------------------
   CT series quality-controlled report (non-NLST, non-JPEG, non-localizer)
   ------------------------------------------------------------- */
WITH base AS (         -- basic modality / compression / collection filters
  SELECT *
  FROM IDC.IDC_V17.DICOM_ALL
  WHERE "Modality" = 'CT'
    AND "collection_name" <> 'NLST'
    AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',      -- JPEG-LS
                                    '1.2.840.10008.1.2.4.51')      -- JPEG-Baseline
    AND "ImageType" NOT ILIKE '%LOCALIZER%'
),
series_quality AS (    -- geometry & uniformity checks (one row per series)
  SELECT
    "SeriesInstanceUID",
    MAX("SeriesNumber")       AS "SeriesNumber",
    MAX("StudyInstanceUID")   AS "StudyInstanceUID",
    MAX("PatientID")          AS "PatientID",
    COUNT(*)                  AS inst_cnt,
    COUNT(DISTINCT TO_VARCHAR("ImagePositionPatient"))             AS ipp_cnt,
    COUNT(DISTINCT TO_VARCHAR("ImageOrientationPatient"))          AS orient_cnt,
    COUNT(DISTINCT TO_VARCHAR("PixelSpacing"))                     AS pxspace_cnt,
    COUNT(DISTINCT "Rows")                                         AS rows_cnt,
    COUNT(DISTINCT "Columns")                                      AS cols_cnt,
    COUNT(DISTINCT CONCAT( ("ImagePositionPatient")[0]::STRING,
                           ',', 
                           ("ImagePositionPatient")[1]::STRING))   AS ipp_xy_cnt,
    COUNT(DISTINCT TO_VARCHAR("SliceThickness"))                   AS slice_thick_vals,
    MAX(ABS( (("ImageOrientationPatient")[0]::FLOAT)* (("ImageOrientationPatient")[4]::FLOAT)
            -(("ImageOrientationPatient")[1]::FLOAT)* (("ImageOrientationPatient")[3]::FLOAT)))  AS dotk_max,
    MIN(ABS( (("ImageOrientationPatient")[0]::FLOAT)* (("ImageOrientationPatient")[4]::FLOAT)
            -(("ImageOrientationPatient")[1]::FLOAT)* (("ImageOrientationPatient")[3]::FLOAT)))  AS dotk_min
  FROM base
  GROUP BY "SeriesInstanceUID"
  HAVING orient_cnt   = 1        -- identical orientation
     AND pxspace_cnt  = 1        -- identical pixel spacing
     AND rows_cnt     = 1        -- identical rows
     AND cols_cnt     = 1        -- identical columns
     AND inst_cnt     = ipp_cnt  -- one slice position per instance
     AND ipp_xy_cnt   = 1        -- identical X & Y position components
     AND dotk_min >= 0.99        -- |dot| within 1 ± 0.01
     AND dotk_max <= 1.01
),
z_positions AS (       -- collect Z-positions for qualified series
  SELECT
    b."SeriesInstanceUID",
    ("ImagePositionPatient")[2]::FLOAT AS z_pos
  FROM base b
  JOIN series_quality q ON q."SeriesInstanceUID" = b."SeriesInstanceUID"
),
z_diffs AS (           -- consecutive slice interval differences
  SELECT
    "SeriesInstanceUID",
    z_pos - LAG(z_pos) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY z_pos) AS z_diff
  FROM z_positions
),
slice_metrics AS (
  SELECT
    "SeriesInstanceUID",
    MAX(z_diff)                                   AS diff_max,
    MIN(z_diff)                                   AS diff_min,
    MAX(z_diff) - MIN(z_diff)                     AS diff_tol
  FROM z_diffs
  WHERE z_diff IS NOT NULL
  GROUP BY "SeriesInstanceUID"
),
exposure_metrics AS (
  SELECT
    "SeriesInstanceUID",
    COUNT(DISTINCT "Exposure")                    AS exposure_distinct,
    MAX(TRY_TO_NUMBER("Exposure"))               AS exposure_max,
    MIN(TRY_TO_NUMBER("Exposure"))               AS exposure_min,
    MAX(TRY_TO_NUMBER("Exposure")) 
      - MIN(TRY_TO_NUMBER("Exposure"))           AS exposure_range
  FROM base
  WHERE "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM series_quality)
  GROUP BY "SeriesInstanceUID"
),
size_metrics AS (
  SELECT
    "SeriesInstanceUID",
    SUM("instance_size")/1048576.0                AS size_mib
  FROM base
  WHERE "SeriesInstanceUID" IN (SELECT "SeriesInstanceUID" FROM series_quality)
  GROUP BY "SeriesInstanceUID"
)

/* ------------------  Final report  --------------------------- */
SELECT
  q."SeriesInstanceUID"                          AS "SERIES_UID",
  q."SeriesNumber"                               AS "SERIES_NO",
  q."StudyInstanceUID"                           AS "STUDY_UID",
  q."PatientID"                                  AS "PATIENT_ID",
  q.dotk_max                                     AS "DOT_K_MAX",
  q.inst_cnt                                     AS "SOP_INSTANCES",
  q.slice_thick_vals                             AS "SLICE_THICK_VALS",
  sm.diff_max                                    AS "DIFF_MAX",
  sm.diff_min                                    AS "DIFF_MIN",
  sm.diff_tol                                    AS "DIFF_TOL",
  em.exposure_distinct                           AS "EXPOSURE_DISTINCT",
  em.exposure_max                                AS "EXPOSURE_MAX",
  em.exposure_min                                AS "EXPOSURE_MIN",
  em.exposure_range                              AS "EXPOSURE_RANGE",
  sz.size_mib                                    AS "SIZE_MIB"
FROM series_quality q
LEFT JOIN slice_metrics    sm ON sm."SeriesInstanceUID" = q."SeriesInstanceUID"
LEFT JOIN exposure_metrics em ON em."SeriesInstanceUID" = q."SeriesInstanceUID"
LEFT JOIN size_metrics     sz ON sz."SeriesInstanceUID" = q."SeriesInstanceUID"
ORDER BY
  sm.diff_tol      DESC NULLS LAST,
  em.exposure_range DESC NULLS LAST,
  q."SeriesInstanceUID" DESC;