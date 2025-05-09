/* -------------------------------------------------------------
   CT series quality-controlled and summarised as requested
   -------------------------------------------------------------
*/
WITH instance_cte AS (   -- one row per DICOM instance
    SELECT
        d."SeriesInstanceUID",
        d."SeriesNumber",
        d."StudyInstanceUID",
        d."PatientID",
        d."TransferSyntaxUID",
        d."collection_name",
        d."Modality",
        d."SOPInstanceUID",
        d."Rows",
        d."Columns",
        d."SliceThickness",
        d."instance_size",
        d."Exposure",
        /* string versions used for “all-identical” checks */
        TO_VARCHAR(d."ImageOrientationPatient")            AS orientation_str,
        TO_VARCHAR(d."PixelSpacing")                       AS pixel_spacing_str,
        TO_VARCHAR(d."ImagePositionPatient")               AS ipp_str,
        TO_VARCHAR(d."ImagePositionPatient"[0]) || ',' ||
        TO_VARCHAR(d."ImagePositionPatient"[1])            AS ipp_xy_str,

        /* numeric values used for geometry calculations */
        d."ImageOrientationPatient"[0]::FLOAT  AS o0,
        d."ImageOrientationPatient"[1]::FLOAT  AS o1,
        d."ImageOrientationPatient"[3]::FLOAT  AS o3,
        d."ImageOrientationPatient"[4]::FLOAT  AS o4,
        d."ImagePositionPatient"[2]::FLOAT     AS z_coord,

        /* |normal·vector| dot [0,0,1] |   (axial ≈ 1) */
        ABS( (d."ImageOrientationPatient"[0]::FLOAT*d."ImageOrientationPatient"[4]::FLOAT)
            - (d."ImageOrientationPatient"[1]::FLOAT*d."ImageOrientationPatient"[3]::FLOAT) )
                                                        AS dot_val,

        /* image type (for filtering localizers) */
        p."ImageType"
    FROM  IDC.IDC_V17.DICOM_ALL   d
    LEFT  JOIN IDC.IDC_V17.DICOM_PIVOT p
           ON  d."SOPInstanceUID" = p."SOPInstanceUID"

    WHERE
          d."Modality" = 'CT'                                  -- CT only
      AND d."collection_name" <> 'NLST'                        -- exclude NLST
      AND d."TransferSyntaxUID" NOT IN
          ('1.2.840.10008.1.2.4.70',   -- JPEG-Lossless
           '1.2.840.10008.1.2.4.51')   -- JPEG-Baseline
),
/* z-spacing for every slice */
interval_cte AS (
    SELECT
        i.*,
        ABS( i.z_coord
            - LAG(i.z_coord) OVER (PARTITION BY i."SeriesInstanceUID"
                                    ORDER BY i.z_coord) )     AS z_interval
    FROM instance_cte i
),
/* roll-up to series level and apply all required “identical” / count checks */
series_cte AS (
    SELECT
        i."SeriesInstanceUID"           AS series_uid,
        MIN(i."SeriesNumber")           AS series_number,
        MIN(i."StudyInstanceUID")       AS study_uid,
        MIN(i."PatientID")              AS patient_id,

        /* geometry */
        MAX(i.dot_val)                  AS max_dot_product,
        MIN(i.dot_val)                  AS min_dot_product,

        COUNT(*)                        AS sop_cnt,

        /* thickness & z-spacing */
        COUNT(DISTINCT i."SliceThickness")       AS slice_thick_dist_cnt,
        MAX(z_interval)                          AS max_z_diff,
        MIN(z_interval)                          AS min_z_diff,
        MAX(z_interval) - MIN(z_interval)        AS z_diff_tolerance,

        /* exposure */
        COUNT(DISTINCT i."Exposure")             AS exposure_dist_cnt,
        MAX(TRY_TO_DOUBLE(i."Exposure"))         AS max_exposure,
        MIN(TRY_TO_DOUBLE(i."Exposure"))         AS min_exposure,
        MAX(TRY_TO_DOUBLE(i."Exposure"))
          - MIN(TRY_TO_DOUBLE(i."Exposure"))     AS exposure_range,

        /* series size in MiB */
        SUM(i."instance_size")/1024/1024.0       AS series_size_mib,

        /* “all-identical” tests prepared for HAVING */
        COUNT(DISTINCT i.orientation_str)        AS orient_variants,
        COUNT(DISTINCT i.pixel_spacing_str)      AS pspc_variants,
        COUNT(DISTINCT i.ipp_str)                AS ipp_dist_cnt,
        COUNT(DISTINCT i.ipp_xy_str)             AS ipp_xy_dist_cnt,
        COUNT(DISTINCT i."Rows")                 AS row_variants,
        COUNT(DISTINCT i."Columns")              AS col_variants,

        /* any localizer frames? */
        MAX( CASE WHEN UPPER(i."ImageType") LIKE '%LOCALIZER%' THEN 1 ELSE 0 END )
                                               AS has_localizer
    FROM interval_cte i
    GROUP BY i."SeriesInstanceUID"
)
SELECT
    series_uid                              AS "SeriesInstanceUID",
    series_number                           AS "SeriesNumber",
    study_uid                               AS "StudyInstanceUID",
    patient_id                              AS "PatientID",

    max_dot_product                         AS "MaxDotProduct",
    sop_cnt                                 AS "SOPInstanceCount",

    slice_thick_dist_cnt                    AS "DistinctSliceThicknessCount",
    max_z_diff                              AS "MaxSliceIntervalDiff",
    min_z_diff                              AS "MinSliceIntervalDiff",
    z_diff_tolerance                        AS "SliceIntervalTolerance",

    exposure_dist_cnt                       AS "DistinctExposureCount",
    max_exposure                            AS "MaxExposure",
    min_exposure                            AS "MinExposure",
    exposure_range                          AS "ExposureRange",

    series_size_mib                         AS "SeriesSize_MiB"

FROM series_cte
/* enforce all mandatory QC criteria */
WHERE
        orient_variants      = 1              -- single orientation
    AND pspc_variants        = 1              -- identical pixel spacing
    AND ipp_dist_cnt         = sop_cnt        -- one position per slice
    AND ipp_xy_dist_cnt      = 1              -- identical x,y positions
    AND row_variants         = 1              -- identical rows
    AND col_variants         = 1              -- identical columns
    AND min_dot_product     >= 0.99           -- axial (|dot| ≥ 0.99)
    AND has_localizer        = 0              -- no localizer images
ORDER BY
      z_diff_tolerance  DESC NULLS LAST,
      exposure_range    DESC NULLS LAST,
      series_uid        DESC NULLS LAST;