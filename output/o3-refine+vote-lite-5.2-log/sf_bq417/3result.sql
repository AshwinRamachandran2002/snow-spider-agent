WITH "filtered" AS (
    SELECT
        dp."collection_id",
        dp."PatientID",
        dp."PatientAge",
        dp."PatientSex",
        dp."StudyInstanceUID",
        dp."SeriesInstanceUID",
        dp."SeriesDescription",
        dp."BodyPartExamined",
        dp."StudyDate",
        dp."instance_size"
    FROM IDC.IDC_V17."DICOM_PIVOT"  dp
    WHERE dp."PatientSex" = 'M'
          AND dp."BodyPartExamined" = 'MEDIASTINUM'
          AND TRY_TO_NUMBER(REGEXP_SUBSTR(dp."PatientAge", '\\d+')) = 18
          AND dp."StudyDate" > '2014-09-01'
)

SELECT
    f."collection_id",
    f."PatientID",
    f."PatientAge",
    f."PatientSex",
    f."StudyInstanceUID",
    f."SeriesInstanceUID",
    f."StudyDate",
    f."SeriesDescription",
    f."BodyPartExamined",
    am."series_aws_url",
    ROUND(SUM(f."instance_size")/1000000 , 2) AS "SeriesSizeMB"
FROM "filtered" f
LEFT JOIN IDC.IDC_V17."AUXILIARY_METADATA" am
       ON f."SeriesInstanceUID" = am."SeriesInstanceUID"
GROUP BY
    f."collection_id",
    f."PatientID",
    f."PatientAge",
    f."PatientSex",
    f."StudyInstanceUID",
    f."SeriesInstanceUID",
    f."StudyDate",
    f."SeriesDescription",
    f."BodyPartExamined",
    am."series_aws_url"
ORDER BY "SeriesSizeMB" DESC NULLS LAST,
         f."SeriesInstanceUID";