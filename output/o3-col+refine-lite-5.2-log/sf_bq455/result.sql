/*  Top‑5 largest CT series (non‑NLST) that meet all quality‑control criteria  */
WITH per_series AS (   -- one row per series
    SELECT
        "SeriesInstanceUID",
        ANY_VALUE("SeriesNumber")      AS "SeriesNumber",
        ANY_VALUE("PatientID")         AS "PatientID",
        COUNT(*)                       AS img_cnt,
        SUM("instance_size") / (1024*1024)  AS series_size_mib,

        /* consistency / exclusion counts */
        COUNT(DISTINCT "ImageOrientationPatient")                    AS orient_cnt,
        COUNT(DISTINCT "PixelSpacing")                               AS pixspace_cnt,
        COUNT(DISTINCT "Rows")                                       AS rows_cnt,
        COUNT(DISTINCT "Columns")                                    AS cols_cnt,
        COUNT_IF("TransferSyntaxUID" IN
                 ('1.2.840.10008.1.2.4.70','1.2.840.10008.1.2.4.51')) AS jpeg_cnt,
        COUNT_IF(LOWER(TO_VARCHAR("ImageType")) LIKE '%localizer%')  AS localizer_cnt,

        /* geometry checks */
        COUNT(DISTINCT ("ImagePositionPatient"[2]::STRING))          AS z_cnt,
        ANY_VALUE("ImageOrientationPatient")                         AS orient_var
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "Modality"      = 'CT'
      AND "collection_id" <> 'nlst'
    GROUP BY "SeriesInstanceUID"
),
with_orientation AS (     -- derive z‑component of orientation cross‑product
    SELECT
        ps.*,
        CAST(orient_var[0]::STRING AS FLOAT) AS ix,
        CAST(orient_var[1]::STRING AS FLOAT) AS iy,
        CAST(orient_var[3]::STRING AS FLOAT) AS jx,
        CAST(orient_var[4]::STRING AS FLOAT) AS jy
    FROM per_series ps
),
filtered AS (             -- keep only series fulfilling every requirement
    SELECT *,
           ABS(ix*jy - iy*jx) AS cross_z
    FROM with_orientation
    WHERE jpeg_cnt     = 0          -- no JPEG‑compressed transfer syntaxes
      AND localizer_cnt= 0          -- no LOCALIZER images
      AND orient_cnt   = 1          -- one unique ImageOrientationPatient
      AND pixspace_cnt = 1          -- one unique PixelSpacing
      AND rows_cnt     = 1          -- consistent Rows
      AND cols_cnt     = 1          -- consistent Columns
      AND z_cnt        = img_cnt    -- images ↔ unique z positions
      AND ABS(cross_z) BETWEEN 0.99 AND 1.01   -- axial (or flipped) orientation
)
SELECT
    "SeriesInstanceUID",
    "SeriesNumber",
    "PatientID",
    ROUND(series_size_mib,2) AS series_size_mib
FROM filtered
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;