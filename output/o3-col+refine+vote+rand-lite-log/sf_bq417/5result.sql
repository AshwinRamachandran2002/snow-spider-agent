-- Identification, study/series details, AWS storage location, and total size (MB)
-- for male patients exactly 18 years old whose BodyPartExamined = 'MEDIASTINUM'
-- and whose StudyDate is after 2014-09-01
SELECT
    p."PatientID",
    p."PatientAge",
    p."PatientSex",
    p."BodyPartExamined",
    p."StudyDate",
    p."StudyInstanceUID",
    p."SeriesInstanceUID",
    a."series_aws_url",
    ROUND(SUM(a."instance_size") / 1000000.0, 2) AS "series_size_MB"
FROM  IDC.IDC_V17.DICOM_PIVOT  AS p
JOIN  IDC.IDC_V17.DICOM_ALL    AS a
      ON p."SeriesInstanceUID" = a."SeriesInstanceUID"
WHERE p."PatientSex" = 'M'
  AND UPPER(p."BodyPartExamined") = 'MEDIASTINUM'
  AND p."StudyDate" > '2014-09-01'
  -- keep only ages that end with ‘Y’ (years) and whose numeric part equals 18
  AND UPPER(p."PatientAge") LIKE '%Y'
  AND TRY_TO_NUMBER(REGEXP_SUBSTR(p."PatientAge", '[0-9]+')) = 18
GROUP BY
    p."PatientID",
    p."PatientAge",
    p."PatientSex",
    p."BodyPartExamined",
    p."StudyDate",
    p."StudyInstanceUID",
    p."SeriesInstanceUID",
    a."series_aws_url";