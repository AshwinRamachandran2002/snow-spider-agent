WITH clean AS (  -- pre-filter individual CT images
    SELECT
        "SeriesInstanceUID",
        "SeriesNumber",
        "PatientID",
        "instance_size",
        "ImageOrientationPatient",
        -- split orientation array elements
        ("ImageOrientationPatient"[0]::FLOAT) AS x1,
        ("ImageOrientationPatient"[1]::FLOAT) AS y1,
        ("ImageOrientationPatient"[3]::FLOAT) AS x2,
        ("ImageOrientationPatient"[4]::FLOAT) AS y2,
        -- image position (patient) coordinates
        ("ImagePositionPatient"[0]::FLOAT)    AS posx,
        ("ImagePositionPatient"[1]::FLOAT)    AS posy,
        ("ImagePositionPatient"[2]::FLOAT)    AS posz,
        "PixelSpacing",
        "Rows",
        "Columns"
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "Modality" = 'CT'                           -- CT only
      AND "collection_id" <> 'nlst'                  -- exclude NLST collection
      AND ( "ImageType" IS NULL                      -- exclude LOCALIZER images
            OR "ImageType" NOT ILIKE '%LOCALIZER%' )
      AND "TransferSyntaxUID" NOT IN                 -- exclude JPEG–compressed
            ('1.2.840.10008.1.2.4.70',
             '1.2.840.10008.1.2.4.51')
      AND "ImageOrientationPatient" IS NOT NULL      -- require orientation & position
      AND "ImagePositionPatient"   IS NOT NULL
),
qualified_series AS (  -- keep only series fulfilling every consistency rule
    SELECT
        "SeriesInstanceUID",
        MAX("SeriesNumber")  AS series_number,
        MAX("PatientID")     AS patient_id,
        SUM("instance_size") AS total_bytes
    FROM clean
    GROUP BY "SeriesInstanceUID"
    HAVING
        -- orientation / spacing / dimensions must be unique per series
        COUNT(DISTINCT "ImageOrientationPatient") = 1
        AND COUNT(DISTINCT "PixelSpacing")        = 1
        AND COUNT(DISTINCT "Rows")               = 1
        AND COUNT(DISTINCT "Columns")            = 1

        -- x- and y-coordinates constant across slices
        AND COUNT(DISTINCT ROUND(posx,6)) = 1
        AND COUNT(DISTINCT ROUND(posy,6)) = 1

        -- no duplicate z positions
        AND COUNT(*) = COUNT(DISTINCT ROUND(posz,6))

        -- cross-product z-component ≈ ±1  ➜ axial (|cosθ|≈1)
        AND MAX(ABS(x1*y2 - y1*x2)) BETWEEN 0.99 AND 1.01
)
SELECT
    "SeriesInstanceUID",
    series_number,
    patient_id,
    ROUND(total_bytes / (1024*1024), 2) AS series_size_mib
FROM qualified_series
ORDER BY series_size_mib DESC NULLS LAST
LIMIT 5;