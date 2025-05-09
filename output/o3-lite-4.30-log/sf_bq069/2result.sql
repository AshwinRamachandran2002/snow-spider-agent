WITH filtered AS (   -- CT images that satisfy the basic exclusion rules
    SELECT
        "SeriesInstanceUID"                                       AS series_uid,
        "collection_name"                                         AS collection,
        "SOPInstanceUID"                                          AS sop_uid,

        /* image‑orientation (row & column direction cosines) */
        ("ImageOrientationPatient")[0]::FLOAT                     AS r1,
        ("ImageOrientationPatient")[1]::FLOAT                     AS r2,
        ("ImageOrientationPatient")[3]::FLOAT                     AS c1,
        ("ImageOrientationPatient")[4]::FLOAT                     AS c2,
        TO_VARCHAR("ImageOrientationPatient")                     AS iop_str,

        /* pixel spacing (as string for equality test) */
        TO_VARCHAR("PixelSpacing")                                AS pixsp_str,

        /* image position (patient) */
        ("ImagePositionPatient")[0]::FLOAT                        AS pos_x,
        ("ImagePositionPatient")[1]::FLOAT                        AS pos_y,
        ("ImagePositionPatient")[2]::FLOAT                        AS pos_z,

        /* exposure and matrix size */
        TRY_TO_NUMBER("Exposure")                                 AS exposure,
        "Rows"                                                    AS n_rows,
        "Columns"                                                 AS n_cols,

        /* individual instance byte size */
        "instance_size"                                           AS inst_size
    FROM   "IDC"."IDC_V17"."DICOM_ALL"
    WHERE  "Modality" = 'CT'
      AND  "collection_name" <> 'NLST'
      AND  "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                       '1.2.840.10008.1.2.4.51')
      AND ( "ImageType" IS NULL OR NOT ("ImageType" ILIKE '%LOCALIZER%') )
),

/* ---------- per‑series quality checks ---------- */
series_qc AS (
    SELECT
        series_uid,
        collection,

        /* z‑component of (row × col) cross‑product */
        ABS( MIN(r1) * MIN(c2) - MIN(r2) * MIN(c1) )              AS dot_z,

        COUNT(*)                                                  AS num_images,
        SUM(inst_size)                                            AS total_bytes
    FROM   filtered
    GROUP  BY series_uid, collection
    HAVING
        ABS( MIN(r1) * MIN(c2) - MIN(r2) * MIN(c1) ) BETWEEN 0.99 AND 1.01
        AND COUNT(DISTINCT iop_str)            = 1    -- single orientation
        AND COUNT(DISTINCT pixsp_str)          = 1    -- single pixel spacing
        AND COUNT(DISTINCT n_rows)             = 1
        AND COUNT(DISTINCT n_cols)             = 1
        AND COUNT(DISTINCT TO_VARCHAR(pos_x))  = 1
        AND COUNT(DISTINCT TO_VARCHAR(pos_y))  = 1
        AND COUNT(*) = COUNT(DISTINCT TO_VARCHAR(pos_z))          -- #images = #slices
),

/* ---------- slice‑spacing statistics ---------- */
z_diffs AS (
    SELECT
        f.series_uid,
        ABS( pos_z
           - LAG(pos_z) OVER (PARTITION BY f.series_uid ORDER BY pos_z)
        ) AS z_diff
    FROM   filtered f
    JOIN   series_qc s ON s.series_uid = f.series_uid
),
z_stats AS (
    SELECT
        series_uid,
        AVG(z_diff)                               AS mean_slice_interval_mm,
        MAX(z_diff) - MIN(z_diff)                 AS diff_slice_interval_mm
    FROM   z_diffs
    WHERE  z_diff IS NOT NULL
    GROUP  BY series_uid
),

/* ---------- exposure statistics ---------- */
exp_stats AS (
    SELECT
        f.series_uid,
        AVG(exposure)                             AS mean_exposure_mAs,
        MAX(exposure) - MIN(exposure)             AS diff_exposure_mAs
    FROM   filtered f
    JOIN   series_qc s ON s.series_uid = f.series_uid
    WHERE  exposure IS NOT NULL
    GROUP  BY f.series_uid
)

/* ---------- final report ---------- */
SELECT
    s.series_uid                               AS series_instance_uid,
    s.collection,
    s.num_images,
    ROUND(z.mean_slice_interval_mm, 4)         AS mean_slice_interval_mm,
    ROUND(z.diff_slice_interval_mm, 4)         AS diff_slice_interval_mm,
    ROUND(e.mean_exposure_mAs, 4)              AS mean_exposure_mAs,
    ROUND(e.diff_exposure_mAs, 4)              AS diff_exposure_mAs,
    ROUND(s.total_bytes / (1024 * 1024), 4)    AS series_size_mb
FROM   series_qc  s
LEFT   JOIN z_stats  z ON z.series_uid = s.series_uid
LEFT   JOIN exp_stats e ON e.series_uid = s.series_uid
ORDER  BY z.diff_slice_interval_mm DESC NULLS LAST,
          e.diff_exposure_mAs      DESC NULLS LAST,
          s.series_uid             DESC;