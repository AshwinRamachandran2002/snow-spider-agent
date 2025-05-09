SELECT
    "PatientID",
    "PatientSex",
    "PatientAge",
    "StudyDate",
    "BodyPartExamined",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    "series_aws_url"                         AS "SeriesAWSURL",
    ROUND(SUM("instance_size") / 1000000.0, 2) AS "SeriesSizeMB"
FROM   "IDC"."IDC_V17"."DICOM_ALL"
WHERE  "PatientSex" = 'M'
  AND  TO_NUMBER(REGEXP_SUBSTR("PatientAge", '[0-9]+')) = 18   -- exactly 18 years old
  AND  UPPER("BodyPartExamined") = 'MEDIASTINUM'               -- body part filter
  AND  "StudyDate" > '2014-09-01'                              -- study date after 2014-09-01
GROUP BY
    "PatientID",
    "PatientSex",
    "PatientAge",
    "StudyDate",
    "BodyPartExamined",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    "series_aws_url"
ORDER BY
    "PatientID",
    "SeriesInstanceUID";