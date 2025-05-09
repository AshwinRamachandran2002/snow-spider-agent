/*  Information requested:
      – identification details (collection and patient)
      – study & series information
      – storage location (Series‑level S3 path with wildcard)
      – total size of each series in MB
   Filters:
      • male patients
      • PatientAge = 18 years (numeric part = 18)
      • BodyPartExamined = 'MEDIASTINUM'
      • StudyDate > 2014‑09‑01
*/
WITH series_size AS (   -- pre‑compute size (MB) of every series
    SELECT
        "SeriesInstanceUID",
        ROUND(SUM("instance_size")/1000000, 2) AS "SeriesSizeMB"
    FROM IDC.IDC_V17.DICOM_ALL
    GROUP BY "SeriesInstanceUID"
),
eligible_series AS (    -- rows that satisfy the clinical/temporal criteria
    SELECT
        "collection_id"                          AS "Collection_ID",
        "PatientID",
        "StudyInstanceUID",
        "SeriesInstanceUID",
        "StudyDate",
        "SeriesDescription",
        "SeriesNumber",
        "BodyPartExamined",
        "PatientAge",
        /* create a series‑level S3 URL that can be wildcard‑expanded */
        CONCAT("series_aws_url", '*')            AS "Series_AWS_URL"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE
        "PatientSex"            = 'M'
        AND "BodyPartExamined"  = 'MEDIASTINUM'
        AND "StudyDate"         > '2014-09-01'
        AND TRY_TO_NUMBER(REGEXP_SUBSTR("PatientAge", '\\d+')) = 18
    GROUP BY
        "collection_id", "PatientID", "StudyInstanceUID", "SeriesInstanceUID",
        "StudyDate", "SeriesDescription", "SeriesNumber",
        "BodyPartExamined", "PatientAge", "series_aws_url"
)
SELECT
    e."Collection_ID",
    e."PatientID",
    e."StudyInstanceUID",
    e."SeriesInstanceUID",
    e."StudyDate",
    e."SeriesDescription",
    e."SeriesNumber",
    e."BodyPartExamined",
    e."PatientAge",
    e."Series_AWS_URL",
    s."SeriesSizeMB"
FROM eligible_series e
JOIN series_size  s
  ON e."SeriesInstanceUID" = s."SeriesInstanceUID"
ORDER BY
    e."Collection_ID",
    e."PatientID",
    e."StudyDate",
    e."SeriesNumber"
;