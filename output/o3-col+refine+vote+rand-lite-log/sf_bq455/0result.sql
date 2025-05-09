WITH candidate_series AS (
    /* ------------------------------------------------------------------
       Identify CT series (not in NLST) that satisfy all QC constraints
       ------------------------------------------------------------------ */
    SELECT
        da."SeriesInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL  da
    WHERE da."Modality" = 'CT'
          /* exclude NLST collection                                               */
      AND da."collection_id" <> 'nlst'
          /* exclude JPEG-compressed transfer syntaxes                             */
      AND da."TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                         '1.2.840.10008.1.2.4.51')
          /* drop any series that contains LOCALIZER images                        */
      AND NOT EXISTS (
              SELECT 1
              FROM IDC.IDC_V17.DICOM_PIVOT dp
              WHERE dp."SeriesInstanceUID" = da."SeriesInstanceUID"
                AND dp."ImageType" ILIKE '%LOCALIZER%'
          )
    GROUP BY da."SeriesInstanceUID"
    HAVING
          /* single orientation per series                                         */
          COUNT(DISTINCT TO_VARCHAR(da."ImageOrientationPatient")) = 1
          /* single pixel-spacing, rows, columns                                   */
      AND COUNT(DISTINCT TO_VARCHAR(da."PixelSpacing")) = 1
      AND COUNT(DISTINCT da."Rows")   = 1
      AND COUNT(DISTINCT da."Columns")= 1
          /* ensure one slice per unique z-position (no duplicates)                */
      AND COUNT(*) = COUNT(DISTINCT (da."ImagePositionPatient"[2]::FLOAT))
          /* orientation must be axial (|cross-product z| ≈ 1)                     */
      AND ABS(
              (MAX(da."ImageOrientationPatient"[0]::FLOAT)
               * MAX(da."ImageOrientationPatient"[4]::FLOAT))
            - (MAX(da."ImageOrientationPatient"[1]::FLOAT)
               * MAX(da."ImageOrientationPatient"[3]::FLOAT))
          ) BETWEEN 0.99 AND 1.01
)
/* --------------------------------------------------------------------------
   Aggregate size for qualifying series and return the five largest
   -------------------------------------------------------------------------- */
SELECT
    da."SeriesInstanceUID",
    MAX(da."SeriesNumber")                         AS "SeriesNumber",
    MAX(da."PatientID")                            AS "PatientID",
    ROUND(SUM(da."instance_size")/1048576.0, 4)    AS "series_size_MiB"
FROM IDC.IDC_V17.DICOM_ALL da
JOIN candidate_series cs
  ON cs."SeriesInstanceUID" = da."SeriesInstanceUID"
GROUP BY da."SeriesInstanceUID"
ORDER BY "series_size_MiB" DESC NULLS LAST
LIMIT 5;