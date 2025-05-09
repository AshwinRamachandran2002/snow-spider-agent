SELECT
    "PatientID"                         AS patient_id,
    "StudyInstanceUID"                  AS study_instance_uid,
    "SeriesInstanceUID"                 AS series_instance_uid,
    MAX("series_aws_url")               AS storage_path,
    ROUND(SUM("instance_size")/1000000, 4) AS total_size_mb
FROM IDC.IDC_V17.DICOM_ALL
WHERE "PatientSex" = 'M'
  AND "BodyPartExamined" = 'MEDIASTINUM'
  AND "StudyDate" > '2014-09-01'
  AND TRY_TO_NUMBER(SUBSTR("PatientAge", 1, LENGTH("PatientAge") - 1)) = 18
GROUP BY
    "PatientID",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "PatientID",
    "SeriesInstanceUID";