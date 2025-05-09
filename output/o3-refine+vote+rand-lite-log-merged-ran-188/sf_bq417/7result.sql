SELECT 
    p."PatientID",
    p."StudyInstanceUID",
    p."SeriesInstanceUID",
    MIN(a."series_aws_url")                              AS "series_aws_url",
    ROUND(SUM(a."instance_size") / 1000000, 2)           AS "series_size_MB"
FROM  IDC.IDC_V17.DICOM_PIVOT  p
JOIN  IDC.IDC_V17.DICOM_ALL    a
      ON p."SeriesInstanceUID" = a."SeriesInstanceUID"
WHERE p."PatientSex" = 'M'
  -- keep rows whose numeric age component equals 18 (e.g., “018Y” or “18Y”)
  AND TRY_TO_NUMBER(REGEXP_SUBSTR(p."PatientAge", '^(\\d{1,3})')) = 18
  AND p."BodyPartExamined" = 'MEDIASTINUM'
  AND p."StudyDate" > '2014-09-01'
GROUP BY 
    p."PatientID",
    p."StudyInstanceUID",
    p."SeriesInstanceUID"
ORDER BY 
    p."PatientID",
    p."StudyInstanceUID",
    p."SeriesInstanceUID";