SELECT
    "collection_id"                       AS "CollectionID",
    "PatientID",
    "PatientAge",
    "PatientSex",
    "StudyInstanceUID",
    "StudyDate",
    "SeriesInstanceUID",
    "SeriesNumber",
    "SeriesDescription",
    "series_aws_url"                      AS "SeriesAWSURL",
    ROUND(SUM("instance_size")/1000000,2) AS "SeriesSizeMB"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
      "PatientSex" = 'M'
  AND TO_NUMBER(REGEXP_SUBSTR("PatientAge", '[0-9]+')) = 18
  AND "BodyPartExamined" = 'MEDIASTINUM'
  AND "StudyDate" > '2014-09-01'
GROUP BY
    "collection_id",
    "PatientID",
    "PatientAge",
    "PatientSex",
    "StudyInstanceUID",
    "StudyDate",
    "SeriesInstanceUID",
    "SeriesNumber",
    "SeriesDescription",
    "series_aws_url"
ORDER BY
    "SeriesSizeMB" DESC NULLS LAST,
    "SeriesInstanceUID";