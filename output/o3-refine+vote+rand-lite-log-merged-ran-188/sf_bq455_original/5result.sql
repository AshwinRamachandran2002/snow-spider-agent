WITH inst AS (  --  Instance–level data pre‑filtered according to task requirements
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",
        "ImageOrientationPatient",
        "ImagePositionPatient",
        "PixelSpacing",
        "Rows",
        "Columns",
        "SliceThickness",
        "ExposureInmAs",
        TO_VARCHAR("ImageType")          AS img_type_txt,
        "TransferSyntaxUID",
        "collection_id"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "Modality" = 'CT'
      AND "collection_id" <> 'nlst'                                   -- exclude NLST collection
      AND "TransferSyntaxUID" NOT IN (                                -- exclude JPEG‑compressed
             '1.2.840.10008.1.2.4.70',
             '1.2.840.10008.1.2.4.51')
      AND UPPER(TO_VARCHAR("ImageType")) NOT LIKE '%LOCALIZER%'       -- exclude localizers
),
series_stats AS (  --  Aggregate per series and compute required consistency metrics
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")                             AS series_number,
        MAX("PatientID")                                AS patient_id,
        SUM("instance_size")                            AS total_bytes,
        COUNT(*)                                        AS num_images,
        COUNT(DISTINCT TO_VARCHAR("ImageOrientationPatient"))          AS orientations,
        COUNT(DISTINCT TO_VARCHAR("PixelSpacing"))                     AS pixel_spacings,
        COUNT(DISTINCT "Rows")                          AS row_vals,
        COUNT(DISTINCT "Columns")                       AS col_vals,
        COUNT(DISTINCT "SliceThickness")                AS slice_thicknesses,
        COUNT(DISTINCT "ExposureInmAs")                 AS exposure_vals, -- NULLs ignored
        COUNT(DISTINCT ROUND(CAST("ImagePositionPatient"[2] AS FLOAT),5)) AS z_positions,
        MIN("ImageOrientationPatient")                  AS orientation_sample
    FROM inst
    GROUP BY "SeriesInstanceUID"
)
SELECT
    "SeriesInstanceUID",
    series_number,
    patient_id,
    ROUND(total_bytes/1048576,2)        AS series_size_mib
FROM series_stats
WHERE orientations      = 1          -- single orientation
  AND pixel_spacings    = 1          -- single pixel spacing
  AND row_vals          = 1          -- constant rows
  AND col_vals          = 1          -- constant columns
  AND slice_thicknesses = 1          -- constant slice thickness
  AND exposure_vals     <= 1         -- constant (or missing) exposure
  AND z_positions       = num_images -- no duplicate z positions
  AND ABS(  /*  z–component of cross‑product of row & col direction cosines  */
        (CAST(orientation_sample[0] AS FLOAT) * CAST(orientation_sample[4] AS FLOAT) -
         CAST(orientation_sample[1] AS FLOAT) * CAST(orientation_sample[3] AS FLOAT))
      ) BETWEEN 0.99 AND 1.01         -- orientation aligned with imaging plane
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;