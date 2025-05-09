/*  Consolidated search (METADATA ∪ PIVOT) for mediastinum images of 18-year-old males  */
WITH unified_meta AS (   -- union first, THEN filter (per instructions)
    SELECT
        "PatientID",
        "StudyInstanceUID",
        "SeriesInstanceUID",
        "StudyDate",
        "BodyPartExamined",
        "PatientSex",
        "PatientAge"
    FROM IDC.IDC_V17.DICOM_METADATA
    UNION ALL
    SELECT
        "PatientID",
        "StudyInstanceUID",
        "SeriesInstanceUID",
        "StudyDate",
        "BodyPartExamined",
        "PatientSex",
        "PatientAge"
    FROM IDC.IDC_V17.DICOM_PIVOT
),
eligible_series AS (
    SELECT
        u."PatientID",
        u."StudyInstanceUID",
        u."SeriesInstanceUID",
        u."StudyDate"
    FROM unified_meta AS u
    WHERE u."PatientSex" = 'M'
      AND TRY_TO_NUMBER(REGEXP_REPLACE(u."PatientAge",'[^0-9]','')) = 18
      AND u."StudyDate"  > '2014-09-01'
      -- allow any spelling / trailing spaces, case-insensitive
      AND u."BodyPartExamined" ILIKE '%MEDIASTINUM%'
),
series_sizes AS (
    SELECT
        e."PatientID",
        e."StudyInstanceUID",
        e."SeriesInstanceUID",
        e."StudyDate",
        MIN(a."series_aws_url")                          AS "series_aws_url",
        ROUND(SUM(a."instance_size") / 1000000.0, 2)     AS "series_size_MB"
    FROM eligible_series           AS e
    JOIN IDC.IDC_V17.DICOM_ALL     AS a
      ON e."SeriesInstanceUID" = a."SeriesInstanceUID"
    GROUP BY
        e."PatientID",
        e."StudyInstanceUID",
        e."SeriesInstanceUID",
        e."StudyDate"
)

SELECT
    "PatientID",
    "StudyDate",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    "series_aws_url",
    "series_size_MB"
FROM series_sizes
ORDER BY "series_size_MB" DESC NULLS LAST;