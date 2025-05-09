/*  Fixed version ─ avoid the VARIANT→FLOAT conversion error by
    casting the extracted elements to STRING first, then to NUMBER   */

WITH filtered_instances AS (
    /* ------------------------------------------------------------
       1.  keep CT instances, drop NLST, localizers and JPEG series
    -------------------------------------------------------------- */
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "StudyInstanceUID",
        "PatientID",
        /* -------- geometry related attributes ------------------ */
        "ImageOrientationPatient"           AS iop,
        "ImagePositionPatient"              AS ipp,
        "PixelSpacing"                      AS pxsp,
        "Rows",
        "Columns",
        "SliceThickness",
        /* -------- exposure (mA) -------------------------------- */
        COALESCE( "XRayTubeCurrentInmA",
                  TRY_TO_NUMBER("XRayTubeCurrent") )     AS exposure_ma,
        /* -------- other --------------------------------------- */
        "SOPInstanceUID",
        "instance_size"                                        AS inst_bytes
    FROM  "IDC"."IDC_V17"."DICOM_ALL"
    WHERE "Modality"              =  'CT'
      AND "collection_name"       <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',  /* JPEG‑lossless */
                                      '1.2.840.10008.1.2.4.51')  /* JPEG‑baseline */
      AND LOWER( TO_VARCHAR("ImageType") ) NOT LIKE '%localizer%'
),

with_dotproduct AS (
    /* ------------------------------------------------------------
       2.  compute |dot( R×C , [0,0,1] )|  for each instance
    -------------------------------------------------------------- */
    SELECT
        f.*,
        TRY_TO_NUMBER( (iop[0])::STRING ) AS r1,
        TRY_TO_NUMBER( (iop[1])::STRING ) AS r2,
        TRY_TO_NUMBER( (iop[3])::STRING ) AS c1,
        TRY_TO_NUMBER( (iop[4])::STRING ) AS c2,
        TRY_TO_NUMBER( (ipp[0])::STRING ) AS pos_x,
        TRY_TO_NUMBER( (ipp[1])::STRING ) AS pos_y,
        TRY_TO_NUMBER( (ipp[2])::STRING ) AS pos_z,
        TO_VARCHAR(iop)                   AS iop_str,
        TO_VARCHAR(pxsp)                  AS pxsp_str,
        TO_VARCHAR(ipp)                   AS ipp_str,
        /*  Z‑component of R×C  */
        ABS(
            TRY_TO_NUMBER( (iop[0])::STRING ) * TRY_TO_NUMBER( (iop[4])::STRING )
          - TRY_TO_NUMBER( (iop[1])::STRING ) * TRY_TO_NUMBER( (iop[3])::STRING )
        )                                 AS abs_dot_z
    FROM filtered_instances f
),

with_zdiff AS (
    /* ------------------------------------------------------------
       3.  slice‑spacing (Δz) per instance (null for first slice)
    -------------------------------------------------------------- */
    SELECT
        w.*,
        ABS(
            pos_z - LAG(pos_z) OVER (PARTITION BY "SeriesInstanceUID"
                                      ORDER BY pos_z)
        )                                   AS dz
    FROM with_dotproduct w
),

series_agg AS (
    /* ------------------------------------------------------------
       4.  aggregate at series level and impose geometry rules
    -------------------------------------------------------------- */
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")                        AS series_number,
        MAX("StudyInstanceUID")                    AS study_uid,
        MAX("PatientID")                           AS patient_id,
        MAX(abs_dot_z)                             AS max_dot_prod,
        COUNT(*)                                   AS n_instances,
        COUNT(DISTINCT iop_str)                    AS n_iop,
        COUNT(DISTINCT pxsp_str)                   AS n_pxsp,
        COUNT(DISTINCT ipp_str)                    AS n_ipp,
        COUNT(DISTINCT TO_VARCHAR(pos_x)||','||TO_VARCHAR(pos_y)) AS n_xy,
        COUNT(DISTINCT "Rows")                     AS n_rows,
        COUNT(DISTINCT "Columns")                  AS n_cols,
        COUNT(DISTINCT "SliceThickness")           AS n_slice_thk,
        MIN(dz)                                    AS min_dz,
        MAX(dz)                                    AS max_dz,
        MAX(dz) - MIN(dz)                          AS dz_tolerance,
        COUNT(DISTINCT exposure_ma)                AS n_expo,
        MAX(exposure_ma)                           AS max_expo,
        MIN(exposure_ma)                           AS min_expo,
        MAX(exposure_ma) - MIN(exposure_ma)        AS expo_range,
        SUM(inst_bytes) / 1048576.0                AS size_mib
    FROM with_zdiff
    GROUP BY "SeriesInstanceUID"
    HAVING
          n_iop   = 1
      AND n_pxsp  = 1
      AND n_rows  = 1
      AND n_cols  = 1
      AND n_xy    = 1
      AND n_instances = n_ipp
      AND max_dot_prod BETWEEN 0.99 AND 1.01
)

SELECT
    "SeriesInstanceUID"                           AS "SERIES_UID",
    series_number                                 AS "SERIES_NUMBER",
    study_uid                                     AS "STUDY_UID",
    patient_id                                    AS "PATIENT_ID",
    max_dot_prod                                  AS "MAX_DOT_PRODUCT",
    n_instances                                   AS "NUM_INSTANCES",
    n_slice_thk                                   AS "SLICE_THK_VARIATIONS",
    max_dz                                        AS "MAX_SLICE_INT_DIFF",
    min_dz                                        AS "MIN_SLICE_INT_DIFF",
    dz_tolerance                                  AS "SLICE_INT_TOLERANCE",
    n_expo                                        AS "EXPOSURE_VALUE_COUNT",
    max_expo                                      AS "MAX_EXPOSURE",
    min_expo                                      AS "MIN_EXPOSURE",
    expo_range                                    AS "EXPOSURE_RANGE",
    size_mib                                      AS "SERIES_SIZE_MIB"
FROM   series_agg
ORDER  BY dz_tolerance  DESC NULLS LAST,
          expo_range    DESC NULLS LAST,
          "SERIES_UID"  DESC;