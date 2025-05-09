/* Top-5 largest non-NLST CT series that meet the requested quality/consistency criteria */
WITH filtered AS (               -- 1. basic exclusions
    SELECT
        "SeriesInstanceUID",
        TRY_TO_NUMBER("SeriesNumber")                      AS series_number,
        "PatientID",
        "instance_size",
        "PixelSpacing",
        "Rows",
        "Columns",
        ("ImagePositionPatient"[2])::FLOAT                 AS z_pos,     -- z-coordinate
        ("ImageOrientationPatient"[0])::FLOAT              AS r1,
        ("ImageOrientationPatient"[1])::FLOAT              AS r2,
        ("ImageOrientationPatient"[3])::FLOAT              AS c1,
        ("ImageOrientationPatient"[4])::FLOAT              AS c2,
        "ImageOrientationPatient"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality"        = 'CT'
      AND "collection_id"  <> 'nlst'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                      '1.2.840.10008.1.2.4.51')          -- exclude JPEG-compressed
      AND UPPER(TO_VARCHAR("ImageType")) NOT LIKE '%LOCALIZER%'           -- exclude scout/localizer
),
deltas AS (                      -- 2. slice-spacing per series
    SELECT
        f.*,
        z_pos - LAG(z_pos) OVER (PARTITION BY "SeriesInstanceUID"
                                 ORDER BY z_pos)            AS dz
    FROM filtered f
),
series_stats AS (                -- 3. per-series aggregation
    SELECT
        "SeriesInstanceUID",
        ANY_VALUE(series_number)                     AS series_number,
        ANY_VALUE("PatientID")                       AS patient_id,
        SUM("instance_size")/1024/1024               AS series_size_mib,   -- MiB
        COUNT(*)                                     AS num_images,
        COUNT(DISTINCT z_pos)                        AS num_z,
        COUNT(DISTINCT TO_VARCHAR("ImageOrientationPatient")) AS num_orient,
        COUNT(DISTINCT TO_VARCHAR("PixelSpacing"))   AS num_pxspace,
        COUNT(DISTINCT "Rows")                       AS num_rows,
        COUNT(DISTINCT "Columns")                    AS num_cols,
        COUNT(DISTINCT CASE WHEN dz IS NOT NULL THEN dz END) AS num_spacing_vals,
        ANY_VALUE(r1) AS r1,
        ANY_VALUE(r2) AS r2,
        ANY_VALUE(c1) AS c1,
        ANY_VALUE(c2) AS c2
    FROM deltas
    GROUP BY "SeriesInstanceUID"
),
final AS (                       -- 4. apply consistency rules
    SELECT *,
           ABS(r1*c2 - r2*c1)                      AS orientation_z        -- |normal·z|
    FROM series_stats
    WHERE num_images      = num_z          -- no duplicate slices
      AND num_orient      = 1              -- single orientation
      AND num_pxspace     = 1              -- constant pixel spacing
      AND num_rows        = 1              -- constant rows
      AND num_cols        = 1              -- constant columns
      AND num_spacing_vals <= 1            -- constant slice spacing
      AND ABS(r1*c2 - r2*c1) BETWEEN 0.99 AND 1.01   -- axial (±1 %)
)
-- 5. return five largest qualified series
SELECT
    "SeriesInstanceUID",
    series_number,
    patient_id,
    ROUND(series_size_mib, 2) AS series_size_mib
FROM final
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;