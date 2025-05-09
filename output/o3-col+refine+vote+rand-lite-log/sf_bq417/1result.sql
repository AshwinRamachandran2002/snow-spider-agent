SELECT
    MIN(p."PatientID")            AS "PatientID",
    MIN(p."PatientSex")           AS "PatientSex",
    MIN(p."PatientAge")           AS "PatientAge",
    MIN(p."BodyPartExamined")     AS "BodyPartExamined",
    MIN(p."StudyInstanceUID")     AS "StudyInstanceUID",
    p."SeriesInstanceUID"         AS "SeriesInstanceUID",
    MIN(p."StudyDate")            AS "StudyDate",
    MIN(a."series_aws_url")       AS "series_aws_url",
    ROUND(SUM(a."instance_size") / 1000000, 2) AS "series_size_mb"
FROM   IDC.IDC_V17.DICOM_PIVOT  p
JOIN   IDC.IDC_V17.DICOM_ALL    a
       ON p."SeriesInstanceUID" = a."SeriesInstanceUID"
WHERE  p."PatientSex"        = 'M'
  AND  p."BodyPartExamined"  = 'MEDIASTINUM'
  AND  TRY_TO_NUMBER(REGEXP_SUBSTR(p."PatientAge", '\\d+')) = 18
  AND  p."StudyDate"         > '2014-09-01'
GROUP BY
       p."SeriesInstanceUID"
ORDER BY
       "series_size_mb" DESC NULLS LAST;