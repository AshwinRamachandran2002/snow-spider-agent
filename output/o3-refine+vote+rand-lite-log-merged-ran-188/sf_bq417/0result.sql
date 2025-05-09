SELECT
    p."PatientID",
    p."StudyInstanceUID",
    p."SeriesInstanceUID",
    p."StudyDate",
    ROUND(SUM(a."instance_size") / 1000000, 2) AS "series_size_mb",
    MAX(a."series_aws_url")             AS "series_aws_url"
FROM IDC.IDC_V17.DICOM_PIVOT AS p
JOIN IDC.IDC_V17.DICOM_ALL   AS a
  ON p."SeriesInstanceUID" = a."SeriesInstanceUID"
WHERE p."PatientSex" = 'M'
  -- numeric part of PatientAge equals 18 years
  AND CAST(REGEXP_SUBSTR(p."PatientAge", '[0-9]+') AS INTEGER) = 18
  AND UPPER(p."BodyPartExamined") = 'MEDIASTINUM'
  AND p."StudyDate" > '2014-09-01'
GROUP BY
    p."PatientID",
    p."StudyInstanceUID",
    p."SeriesInstanceUID",
    p."StudyDate"
ORDER BY
    "series_size_mb" DESC NULLS LAST;