SELECT
    "collection_id"                                                   AS "CollectionID",
    "PatientID",
    "PatientAge",
    "PatientSex",
    "StudyInstanceUID",
    "StudyDate",
    "StudyDescription",
    "SeriesInstanceUID",
    "SeriesDate",
    "SeriesDescription",
    "SeriesNumber",
    /* use any non‑null value of the series‑level AWS URL */
    MIN("series_aws_url")                                             AS "SeriesAWSURL",
    /* total size rounded to two decimals, MB = bytes / 1,000,000 */
    ROUND(SUM("instance_size") / 1000000, 2)                          AS "SeriesSizeMB"
FROM  IDC.IDC_V17.DICOM_ALL
WHERE "PatientSex" = 'M'
  AND TRY_TO_NUMBER(REGEXP_SUBSTR("PatientAge", '\\d+')) = 18
  AND "BodyPartExamined" = 'MEDIASTINUM'
  AND "StudyDate" > '2014-09-01'
GROUP BY
    "collection_id",
    "PatientID",
    "PatientAge",
    "PatientSex",
    "StudyInstanceUID",
    "StudyDate",
    "StudyDescription",
    "SeriesInstanceUID",
    "SeriesDate",
    "SeriesDescription",
    "SeriesNumber"
ORDER BY
    "CollectionID",
    "PatientID",
    "StudyDate",
    "SeriesNumber" NULLS LAST;