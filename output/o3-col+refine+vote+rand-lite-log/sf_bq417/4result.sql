SELECT
    p."PatientID"          AS "patient_id",
    p."StudyInstanceUID"   AS "study_instance_uid",
    p."SeriesInstanceUID"  AS "series_instance_uid",
    a."series_aws_url"     AS "series_aws_url",
    ROUND(SUM(a."instance_size") / 1000000, 2) AS "series_size_mb"
FROM
    "IDC"."IDC_V17"."DICOM_PIVOT"  p
JOIN
    "IDC"."IDC_V17"."DICOM_ALL"    a
      ON p."SeriesInstanceUID" = a."SeriesInstanceUID"
WHERE
      p."PatientSex" = 'M'
  AND RIGHT(p."PatientAge", 1) = 'Y'                                         -- ensure units are years
  AND TRY_TO_NUMBER(REGEXP_SUBSTR(p."PatientAge", '^[0-9]+')) = 18           -- exactly 18 years old
  AND p."BodyPartExamined" = 'MEDIASTINUM'
  AND p."StudyDate" > '2014-09-01'
GROUP BY
    p."PatientID",
    p."StudyInstanceUID",
    p."SeriesInstanceUID",
    a."series_aws_url";