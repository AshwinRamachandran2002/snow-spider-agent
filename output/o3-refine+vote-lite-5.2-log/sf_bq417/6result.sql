SELECT
    "collection_id"                             AS "CollectionID",
    "PatientID",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    "StudyDate",
    "SeriesDescription",
    "BodyPartExamined",
    "series_aws_url"                            AS "SeriesAWSURL",
    ROUND(SUM("instance_size") / 1000000, 2)    AS "TotalSeriesSizeMB"
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
    "StudyInstanceUID",
    "SeriesInstanceUID",
    "StudyDate",
    "SeriesDescription",
    "BodyPartExamined",
    "series_aws_url"
ORDER BY
    "TotalSeriesSizeMB" DESC NULLS LAST,
    "SeriesInstanceUID";