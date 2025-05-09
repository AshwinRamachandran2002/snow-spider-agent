SELECT
    p."PatientID",
    p."StudyInstanceUID",
    p."SeriesInstanceUID",
    p."StudyDate",
    p."PatientAge",
    p."PatientSex",
    p."BodyPartExamined",
    a."series_aws_url",
    ROUND(SUM(a."instance_size") / 1000000, 2) AS "series_size_MB"
FROM IDC.IDC_V17.DICOM_PIVOT AS p
JOIN IDC.IDC_V17.DICOM_ALL   AS a
      ON a."SeriesInstanceUID" = p."SeriesInstanceUID"
WHERE p."BodyPartExamined" = 'MEDIASTINUM'                    -- exact body part
  AND p."PatientSex"      = 'M'                               -- male patients
  AND TRY_TO_NUMBER(SUBSTR(p."PatientAge", 1, 3)) = 18        -- exactly 18 years old
  AND p."StudyDate"       > '2014-09-01'                      -- study date after 2014-09-01
GROUP BY
    p."PatientID",
    p."StudyInstanceUID",
    p."SeriesInstanceUID",
    p."StudyDate",
    p."PatientAge",
    p."PatientSex",
    p."BodyPartExamined",
    a."series_aws_url";