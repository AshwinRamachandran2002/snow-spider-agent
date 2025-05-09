/*  QC‑filtered CT series summary (non‑NLST, no JPEG‑lossy, no LOCALIZER)  */
WITH /* ------------------------------------------------ basic filters --- */
pre AS (                          -- raw CT instances that pass base filters
    SELECT  "SeriesInstanceUID",
            "SeriesNumber",
            "StudyInstanceUID",
            "PatientID",
            "ImageOrientationPatient"               AS iop,
            "PixelSpacing"                          AS pixsp,
            "ImagePositionPatient"                  AS ipp,
            "SliceThickness",
            "Exposure",
            "instance_size",
            "Rows",
            "Columns",
            "ImageType",
            /* z‑component of orientation cross‑product dotted with [0,0,1] */
            ABS( ("ImageOrientationPatient"[0]::FLOAT * "ImageOrientationPatient"[4]::FLOAT)
               - ("ImageOrientationPatient"[1]::FLOAT * "ImageOrientationPatient"[3]::FLOAT) )
               AS cross_z
    FROM    IDC.IDC_V17.DICOM_ALL
    WHERE   "Modality" = 'CT'
      AND   "collection_name" <> 'NLST'
      AND   "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',
                                        '1.2.840.10008.1.2.4.51')
),
/* ------------------------------------------------ remove LOCALIZER ----- */
localizer_series AS (
    SELECT  DISTINCT "SeriesInstanceUID"
    FROM    pre,
            LATERAL FLATTEN ( INPUT => "ImageType") t
    WHERE   UPPER(t.value::STRING) LIKE '%LOCALIZER%'
),
flt AS (                          -- instances eligible for QC
    SELECT  *
    FROM    pre
    WHERE   "SeriesInstanceUID" NOT IN (SELECT "SeriesInstanceUID"
                                        FROM   localizer_series)
),
/* ------------------------------------------------ series‑level QC ------ */
series_qc AS (
    SELECT  "SeriesInstanceUID",
            MAX("SeriesNumber")                                AS series_no,
            MAX("StudyInstanceUID")                            AS study_uid,
            MAX("PatientID")                                   AS patient_id,
            MAX(cross_z)                                       AS dot_prod,
            COUNT(*)                                           AS n_inst,
            COUNT(DISTINCT iop::STRING)                        AS n_iop,
            COUNT(DISTINCT pixsp::STRING)                      AS n_pixsp,
            COUNT(DISTINCT ipp::STRING)                        AS n_pos,
            COUNT(DISTINCT CONCAT(ipp[0]::STRING,'|',ipp[1]::STRING)) AS n_xy,
            COUNT(DISTINCT "Rows")                             AS n_rows,
            COUNT(DISTINCT "Columns")                          AS n_cols
    FROM    flt
    GROUP BY "SeriesInstanceUID"
    HAVING  n_iop  = 1
       AND  n_pixsp= 1
       AND  n_inst = n_pos
       AND  n_xy   = 1
       AND  n_rows = 1
       AND  n_cols = 1
       AND  dot_prod BETWEEN 0.99 AND 1.01
),
/* ------------------------------------------------ slice spacing -------- */
dz AS (
    SELECT  f."SeriesInstanceUID",
            ipp[2]::FLOAT                                      AS z_val,
            LAG(ipp[2]::FLOAT) OVER (PARTITION BY f."SeriesInstanceUID"
                                      ORDER BY ipp[2]::FLOAT) AS prev_z
    FROM    flt            f
    JOIN    series_qc      q  ON q."SeriesInstanceUID" = f."SeriesInstanceUID"
),
slice_stats AS (
    SELECT  "SeriesInstanceUID",
            MAX(ABS(z_val - prev_z))                          AS max_dz,
            MIN(ABS(z_val - prev_z))                          AS min_dz,
            MAX(ABS(z_val - prev_z)) - MIN(ABS(z_val - prev_z)) AS tol_dz
    FROM    dz
    WHERE   prev_z IS NOT NULL
    GROUP BY "SeriesInstanceUID"
),
/* ------------------------------------------------ other stats ---------- */
thk AS (
    SELECT  "SeriesInstanceUID",
            COUNT(DISTINCT "SliceThickness")                   AS n_thk
    FROM    flt
    GROUP BY "SeriesInstanceUID"
),
exp AS (
    SELECT  "SeriesInstanceUID",
            COUNT(DISTINCT "Exposure")                         AS n_exp,
            MAX(TRY_TO_NUMBER("Exposure"))                     AS max_exp,
            MIN(TRY_TO_NUMBER("Exposure"))                     AS min_exp,
            MAX(TRY_TO_NUMBER("Exposure")) -
            MIN(TRY_TO_NUMBER("Exposure"))                     AS diff_exp
    FROM    flt
    GROUP BY "SeriesInstanceUID"
),
siz AS (
    SELECT  "SeriesInstanceUID",
            SUM("instance_size") / 1048576.0                   AS size_mib
    FROM    flt
    GROUP BY "SeriesInstanceUID"
)
/* ------------------------------------------------ final report --------- */
SELECT  q."SeriesInstanceUID"                  AS series_uid,
        q.series_no,
        q.study_uid,
        q.patient_id,
        ROUND(q.dot_prod,6)                    AS max_dot_product,
        q.n_inst                               AS num_instances,
        COALESCE(thk.n_thk,0)                  AS n_slice_thk,
        ss.max_dz,
        ss.min_dz,
        ss.tol_dz,
        COALESCE(exp.n_exp,0)                  AS n_exposures,
        exp.max_exp,
        exp.min_exp,
        exp.diff_exp,
        siz.size_mib
FROM    series_qc      q
LEFT JOIN slice_stats  ss  ON ss."SeriesInstanceUID" = q."SeriesInstanceUID"
LEFT JOIN thk          thk ON thk."SeriesInstanceUID" = q."SeriesInstanceUID"
LEFT JOIN exp          exp ON exp."SeriesInstanceUID" = q."SeriesInstanceUID"
LEFT JOIN siz          siz ON siz."SeriesInstanceUID" = q."SeriesInstanceUID"
ORDER BY ss.tol_dz   DESC NULLS LAST,
         exp.diff_exp DESC NULLS LAST,
         q."SeriesInstanceUID" DESC;