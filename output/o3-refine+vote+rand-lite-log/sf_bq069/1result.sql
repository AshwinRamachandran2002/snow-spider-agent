/*  CT series that
    • are NOT from collection NLST
    • are NOT localizers
    • are NOT JPEG‑compressed (TS 1.2.840.10008.1.2.4.70 or 1.2.840.10008.1.2.4.51)
    • pass the requested geometry / consistency checks
*/
WITH inst AS (
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",

        /* string versions used for “identical” tests */
        TO_VARCHAR("ImageOrientationPatient")           AS orient_str,
        TO_VARCHAR("PixelSpacing")                      AS pxsp_str,
        TO_VARCHAR("ImagePositionPatient")              AS ipos_str,

        "Rows"      AS img_rows,
        "Columns"   AS img_cols,

        /* numeric components for geometric checks – cast via STRING first to avoid 22023 error */
        TRY_TO_DOUBLE(("ImageOrientationPatient"[0])::STRING) AS r1,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[1])::STRING) AS r2,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[2])::STRING) AS r3,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[3])::STRING) AS c1,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[4])::STRING) AS c2,
        TRY_TO_DOUBLE(("ImageOrientationPatient"[5])::STRING) AS c3,

        TRY_TO_DOUBLE(("ImagePositionPatient"[0])::STRING)    AS ip_x,
        TRY_TO_DOUBLE(("ImagePositionPatient"[1])::STRING)    AS ip_y,
        TRY_TO_DOUBLE(("ImagePositionPatient"[2])::STRING)    AS ip_z,

        TRY_TO_DOUBLE("SliceThickness"::STRING)               AS slice_thk,
        TRY_TO_DOUBLE("ExposureInmAs"::STRING)                AS exposure_mas,

        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND COALESCE("collection_id", '') <> 'nlst'                       -- exclude NLST
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',         -- skip JPEG
                                      '1.2.840.10008.1.2.4.51')
      AND UPPER("ImageType") NOT LIKE '%LOCALIZER%'                     -- skip localizers
),
/* add |dot product| value for each instance */
inst_dot AS (
    SELECT
        *,
        ABS( (r2 * c1) - (r1 * c2) )         AS dot_val                 -- |(row×col)·k|
    FROM inst
),
/* per‑series aggregates */
series_aggr AS (
    SELECT
        "SeriesInstanceUID",

        MAX("SeriesNumber")             AS series_number,
        MAX("StudyInstanceUID")         AS study_uid,
        MAX("PatientID")                AS patient_id,

        MAX(dot_val)                    AS max_dot,

        COUNT(*)                        AS sop_cnt,
        COUNT(DISTINCT orient_str)      AS orient_cnt,
        COUNT(DISTINCT pxsp_str)        AS pxsp_cnt,
        COUNT(DISTINCT ipos_str)        AS ipos_cnt,

        /* identical first two coordinates of IPP? */
        COUNT(DISTINCT CONCAT(TO_VARCHAR(ip_x), ',', TO_VARCHAR(ip_y))) AS xy_cnt,

        MAX(img_rows)  AS max_rows,  MIN(img_rows)  AS min_rows,
        MAX(img_cols)  AS max_cols,  MIN(img_cols)  AS min_cols,

        COUNT(DISTINCT slice_thk)       AS n_slice_thk,
        COUNT(DISTINCT exposure_mas)    AS n_exposure,
        MAX(exposure_mas)               AS max_exposure,
        MIN(exposure_mas)               AS min_exposure,

        SUM("instance_size")            AS tot_bytes
    FROM inst_dot
    GROUP BY "SeriesInstanceUID"
),
/* slice‑to‑slice z‑spacing */
z_deltas AS (
    SELECT
        "SeriesInstanceUID",
        ABS( LEAD(ip_z) OVER (PARTITION BY "SeriesInstanceUID" ORDER BY ip_z) - ip_z ) AS dz
    FROM inst
),
z_aggr AS (
    SELECT
        "SeriesInstanceUID",
        MAX(dz) AS max_dz,
        MIN(dz) AS min_dz
    FROM z_deltas
    WHERE dz IS NOT NULL
    GROUP BY "SeriesInstanceUID"
)
/* final selection */
SELECT
    s."SeriesInstanceUID"                               AS series_uid,            -- 1
    s.series_number,                                                               -- 2
    s.study_uid,                                                                   -- 3
    s.patient_id,                                                                  -- 4
    s.max_dot,                                                                     -- 5
    s.sop_cnt,                                                                     -- 6
    s.n_slice_thk,                                                                 -- 7
    z.max_dz,                                                                      -- 8
    z.min_dz,                                                                      -- 9
    (z.max_dz - z.min_dz)                             AS slice_interval_tolerance, --10
    s.n_exposure,                                                                  --11
    s.max_exposure,                                                                --12
    s.min_exposure,                                                                --13
    (s.max_exposure - s.min_exposure)                AS exposure_range,            --14
    ROUND(s.tot_bytes / 1024 / 1024, 2)               AS series_size_mib           --15
FROM   series_aggr s
JOIN   z_aggr     z  ON z."SeriesInstanceUID" = s."SeriesInstanceUID"
WHERE  s.orient_cnt   = 1          -- identical orientation
  AND  s.pxsp_cnt     = 1          -- identical pixel spacing
  AND  s.sop_cnt      = s.ipos_cnt -- #SOP == #unique positions
  AND  s.xy_cnt       = 1          -- identical x‑y IPP
  AND  s.max_rows     = s.min_rows -- identical Rows
  AND  s.max_cols     = s.min_cols -- identical Cols
  AND  s.max_dot      >= 0.99      -- near‑axial
ORDER BY
    slice_interval_tolerance DESC NULLS LAST,
    exposure_range           DESC NULLS LAST,
    series_uid               DESC;