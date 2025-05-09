SELECT
    "collection_id"                      AS "CollectionID",
    "PatientID",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    "StudyDate",
    "StudyDescription",
    "BodyPartExamined",
    "Modality",
    "SeriesDate",
    "SeriesDescription",
    "SeriesNumber",
    MIN("series_aws_url")                AS "SeriesAWS_URL",
    COUNT(DISTINCT "SOPInstanceUID")     AS "InstanceCount",
    ROUND(SUM("instance_size")/1000000 , 2)  AS "SeriesSize_MB"
FROM  IDC.IDC_V17.DICOM_ALL
WHERE "PatientSex" = 'M'
  AND TO_NUMBER(REGEXP_SUBSTR("PatientAge", '\\d+')) = 18      -- exactly 18 years old
  AND "BodyPartExamined" = 'MEDIASTINUM'
  AND "StudyDate" > '2014-09-01'                               -- strictly after 1‑Sep‑2014
GROUP BY
    "collection_id",
    "PatientID",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    "StudyDate",
    "StudyDescription",
    "BodyPartExamined",
    "Modality",
    "SeriesDate",
    "SeriesDescription",
    "SeriesNumber"
ORDER BY
    "PatientID",
    "StudyDate",
    "SeriesNumber";