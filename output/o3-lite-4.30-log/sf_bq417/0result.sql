SELECT
    "PatientID"                                                      AS patient_id,
    "StudyInstanceUID"                                               AS study_instance_uid,
    "SeriesInstanceUID"                                              AS series_instance_uid,
    CONCAT('s3://', "aws_bucket", '/', "SeriesInstanceUID", '/*')    AS storage_path,
    ROUND(SUM("instance_size") / 1000000, 4)                         AS total_size_mb
FROM IDC.IDC_V17.DICOM_ALL
WHERE "PatientSex" = 'M'
  AND TRY_TO_NUMBER(REGEXP_REPLACE("PatientAge", '[^0-9]', '')) = 18
  AND "BodyPartExamined" = 'MEDIASTINUM'
  AND "StudyDate" > '2014-09-01'
GROUP BY
    "PatientID",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    "aws_bucket"
ORDER BY
    "PatientID",
    "StudyInstanceUID",
    "SeriesInstanceUID";