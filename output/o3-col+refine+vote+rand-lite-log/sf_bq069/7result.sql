/* -------------------------------------------------------------
   CT series report satisfying geometry / quality constraints
   -------------------------------------------------------------*/
WITH base AS (   -- 1. preliminary filters
    SELECT
        "PatientID",
        "StudyInstanceUID",
        "SeriesInstanceUID",
        "SeriesNumber",
        "InstanceNumber",
        "TransferSyntaxUID",
        "ImageType",
        "ImageOrientationPatient",
        "ImagePositionPatient",
        "PixelSpacing",
        "SliceThickness",
        "Exposure",
        "Rows",
        "Columns",
        "instance_size"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_name" <> 'NLST'
      AND "TransferSyntaxUID" NOT IN ('1.2.840.10008.1.2.4.70',  -- JPEG-LS
                                      '1.2.840.10008.1.2.4.51')  -- JPEG Baseline
      AND TO_VARCHAR("ImageType") NOT ILIKE '%LOCALIZER%'
),
orient_calc AS (     -- 2. vector components & key numeric fields
    SELECT
        b.*,
        ("ImageOrientationPatient")[0]::FLOAT AS r1,
        ("ImageOrientationPatient")[1]::FLOAT AS r2,
        ("ImageOrientationPatient")[2]::FLOAT AS r3,
        ("ImageOrientationPatient")[3]::FLOAT AS c1,
        ("ImageOrientationPatient")[4]::FLOAT AS c2,
        ("ImageOrientationPatient")[5]::FLOAT AS c3,
        ("ImagePositionPatient")[0]::FLOAT    AS pos_x,
        ("ImagePositionPatient")[1]::FLOAT    AS pos_y,
        ("ImagePositionPatient")[2]::FLOAT    AS pos_z,
        NULLIF("SliceThickness",'')::FLOAT    AS slice_thick,
        NULLIF("Exposure",'')::FLOAT          AS exposure_val
    FROM base b
),
dot_product AS (     -- 3. cross-product normal vector & |dot| with [0,0,1]
    SELECT
        *,
        (r2*c3 - r3*c2)                   AS cross_x,
        (r3*c1 - r1*c3)                   AS cross_y,
        (r1*c2 - r2*c1)                   AS cross_z,
        ABS(r1*c2 - r2*c1)                AS dot_abs
    FROM orient_calc
),
z_ordered AS (       -- 4. z-spacing per slice
    SELECT
        d.*,
        pos_z
          - LAG(pos_z) OVER (PARTITION BY "SeriesInstanceUID"
                             ORDER BY pos_z) AS z_diff
    FROM dot_product d
),
series_stats AS (    -- 5. per-series aggregates
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")                               AS series_number,
        MAX("StudyInstanceUID")                           AS study_uid,
        MAX("PatientID")                                  AS patient_id,
        MAX(dot_abs)                                      AS max_dot_product,
        COUNT(*)                                          AS num_instances,
        COUNT(DISTINCT TO_VARCHAR("ImagePositionPatient"))                AS num_unique_positions,
        COUNT(DISTINCT TO_VARCHAR("ImageOrientationPatient"))             AS cnt_orient,
        COUNT(DISTINCT TO_VARCHAR("PixelSpacing"))                         AS cnt_pixsp,
        COUNT(DISTINCT TO_VARCHAR(("ImagePositionPatient")[0]))           AS cnt_x,
        COUNT(DISTINCT TO_VARCHAR(("ImagePositionPatient")[1]))           AS cnt_y,
        COUNT(DISTINCT "Rows")                            AS cnt_rows,
        COUNT(DISTINCT "Columns")                         AS cnt_cols,
        COUNT(DISTINCT slice_thick)                       AS distinct_slice_thickness,
        MAX(z_diff)                                       AS max_slice_interval,
        MIN(z_diff)                                       AS min_slice_interval,
        MAX(z_diff) - MIN(z_diff)                         AS slice_interval_tolerance,
        COUNT(DISTINCT exposure_val)                      AS distinct_exposure_values,
        MAX(exposure_val)                                 AS max_exposure,
        MIN(exposure_val)                                 AS min_exposure,
        MAX(exposure_val) - MIN(exposure_val)             AS exposure_range,
        SUM("instance_size") / 1048576.0                  AS series_size_mib
    FROM z_ordered
    GROUP BY "SeriesInstanceUID"
),
qualified AS (       -- 6. enforce geometry invariants
    SELECT *
    FROM series_stats
    WHERE cnt_orient    = 1
      AND cnt_pixsp     = 1
      AND cnt_x         = 1
      AND cnt_y         = 1
      AND cnt_rows      = 1
      AND cnt_cols      = 1
      AND num_instances = num_unique_positions
      AND max_dot_product BETWEEN 0.99 AND 1.01
)
-- 7. final ordered report -----------------------------------------------------
SELECT
    "SeriesInstanceUID"                       AS series_uid,
    series_number                             AS series_number,
    study_uid                                 AS study_uid,
    patient_id                                AS patient_id,
    ROUND(max_dot_product,4)                  AS max_dot_product,
    num_instances                             AS num_sop_instances,
    distinct_slice_thickness                  AS distinct_slice_thickness,
    ROUND(max_slice_interval,4)               AS max_slice_interval,
    ROUND(min_slice_interval,4)               AS min_slice_interval,
    ROUND(slice_interval_tolerance,4)         AS slice_interval_tolerance,
    distinct_exposure_values                  AS distinct_exposure_values,
    ROUND(max_exposure,4)                     AS max_exposure,
    ROUND(min_exposure,4)                     AS min_exposure,
    ROUND(exposure_range,4)                   AS exposure_range,
    ROUND(series_size_mib,4)                  AS series_size_mib
FROM qualified
ORDER BY slice_interval_tolerance DESC NULLS LAST,
         exposure_range           DESC NULLS LAST,
         series_uid               DESC NULLS LAST;