SELECT
    "PatientID"                                          AS patient_id,
    "StudyInstanceUID"                                   AS study_instance_uid,
    "SeriesInstanceUID"                                  AS series_instance_uid,
    MIN("series_gcs_url")                                AS storage_path,
    ROUND(SUM("instance_size") / 1000000, 4)             AS total_size_mb
FROM "IDC"."IDC_V17"."DICOM_ALL"
WHERE "BodyPartExamined" = 'MEDIASTINUM'
  AND "PatientSex" = 'M'
  AND TRY_TO_NUMBER(TRANSLATE("PatientAge",'ABCDEFGHIJKLMNOPQRSTUVWXYZ','')) = 18
  AND "StudyDate" > '2014-09-01'
GROUP BY
    "PatientID",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    total_size_mb DESC NULLS LAST,
    "SeriesInstanceUID";