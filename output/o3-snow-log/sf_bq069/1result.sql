/*  Report of CT image series that pass all required filters and geometry checks  */
WITH base AS (               --  one row per SOP instance after primary filters
    SELECT
        da."SeriesInstanceUID",
        da."SeriesNumber",
        da."StudyInstanceUID",
        da."PatientID",
        da."SliceThickness",
        TRY_TO_NUMBER(da."Exposure")                        AS exposure_num,
        da."ImageOrientationPatient"                        AS orient,       -- VARIANT
        da."ImagePositionPatient"                           AS pos,          -- VARIANT
        da."PixelSpacing"::STRING                           AS pixsp_str,
        da."ImageOrientationPatient"::STRING                AS orient_str,
        da."Rows",
        da."Columns",
        da."instance_size",
        /*  |(row-vector × col-vector)| · [0,0,1]
            = |a*e − b*d|   where   a=orient[0], b=orient[1], d=orient[3], e=orient[4]  */
        ABS( (orient[0]::FLOAT * orient[4]::FLOAT)
           - (orient[1]::FLOAT * orient[3]::FLOAT) )        AS dot_abs
    FROM  IDC.IDC_V17."DICOM_ALL"  da
    LEFT JOIN IDC.IDC_V17."DICOM_PIVOT"  dp
           ON da."SOPInstanceUID" = dp."SOPInstanceUID"
    WHERE da."Modality"           = 'CT'
      AND da."collection_name"   <> 'NLST'
      AND da."TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',   -- JPEG-LS
                                         '1.2.840.10008.1.2.4.51')   -- JPEG Baseline
      AND (dp."ImageType" IS NULL OR dp."ImageType" NOT ILIKE '%LOCALIZER%')
),
/*  z-spacing between consecutive slices in each series  */
z_diffs AS (
    SELECT
        "SeriesInstanceUID",
        ABS( pos[2]::FLOAT
           - LAG(pos[2]::FLOAT) OVER (PARTITION BY "SeriesInstanceUID"
                                      ORDER BY pos[2]::FLOAT) )         AS z_diff
    FROM base
),
/*  min / max slice spacing per series  */
z_stats AS (
    SELECT
        "SeriesInstanceUID",
        MAX(z_diff)   AS max_z_diff,
        MIN(z_diff)   AS min_z_diff
    FROM z_diffs
    WHERE z_diff IS NOT NULL
    GROUP BY "SeriesInstanceUID"
),
/*  roll-up of per-series values  */
series_raw AS (
    SELECT
        b."SeriesInstanceUID",
        MAX(b."SeriesNumber")                                AS SeriesNumber,
        MAX(b."StudyInstanceUID")                            AS StudyInstanceUID,
        MAX(b."PatientID")                                   AS PatientID,
        MAX(b.dot_abs)                                       AS max_dot,
        MIN(b.dot_abs)                                       AS min_dot,
        COUNT(*)                                             AS num_instances,
        COUNT(DISTINCT b."SliceThickness")                   AS num_slice_thickness,
        COUNT(DISTINCT b.orient_str)                         AS distinct_orient,
        COUNT(DISTINCT b.pixsp_str)                          AS distinct_pixsp,
        COUNT(DISTINCT b."Rows")                             AS distinct_rows,
        COUNT(DISTINCT b."Columns")                          AS distinct_cols,
        COUNT(DISTINCT b.pos::STRING)                        AS distinct_pos,
        COUNT(DISTINCT CONCAT(b.pos[0]::STRING, ',', b.pos[1]::STRING))
                                                             AS distinct_first2_pos,
        COUNT(DISTINCT b.exposure_num)                       AS num_exposure_vals,
        MAX(b.exposure_num)                                  AS max_exposure,
        MIN(b.exposure_num)                                  AS min_exposure,
        SUM(b."instance_size")                               AS total_size_bytes
    FROM base b
    GROUP BY b."SeriesInstanceUID"
),
/*  enforce geometry / uniformity constraints  */
qualified AS (
    SELECT
        sr.*,
        zs.max_z_diff,
        zs.min_z_diff,
        zs.max_z_diff - zs.min_z_diff                        AS tolerance,
        COALESCE(sr.max_exposure,0) - COALESCE(sr.min_exposure,0)
                                                             AS exposure_range
    FROM series_raw sr
    LEFT JOIN z_stats zs
           ON sr."SeriesInstanceUID" = zs."SeriesInstanceUID"
    WHERE sr.distinct_orient     = 1
      AND sr.distinct_pixsp      = 1
      AND sr.distinct_rows       = 1
      AND sr.distinct_cols       = 1
      AND sr.num_instances       = sr.distinct_pos
      AND sr.distinct_first2_pos = 1
      AND sr.min_dot            >= 0.99      --  orientation normal ≈ ±[0,0,1]
)
/*  final report  */
SELECT
    "SeriesInstanceUID"                                AS series_uid,
    SeriesNumber                                       AS series_number,
    StudyInstanceUID                                   AS study_uid,
    PatientID                                          AS patient_id,
    max_dot,
    num_instances                                      AS sop_instances,
    num_slice_thickness,
    max_z_diff,
    min_z_diff,
    tolerance,
    num_exposure_vals,
    max_exposure,
    min_exposure,
    exposure_range,
    ROUND(total_size_bytes / 1048576, 4)               AS series_size_mib
FROM qualified
ORDER BY tolerance      DESC NULLS LAST,
         exposure_range DESC NULLS LAST,
         series_uid     DESC NULLS LAST;