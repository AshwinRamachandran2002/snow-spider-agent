SELECT
    "collection_id"                                 AS "CollectionID",
    "PatientID",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    "StudyDate",
    "SeriesDate",
    "SeriesDescription",
    "SeriesNumber",
    "BodyPartExamined",
    "PatientAge",
    "PatientSex",
    COUNT(DISTINCT "SOPInstanceUID")                AS "InstanceCount",
    ROUND(SUM("instance_size")/1000000, 2)          AS "SeriesSizeMB",
    /* construct series‑level AWS location and append wildcard */
    REGEXP_REPLACE(
        MIN("aws_url"),
        '/[^/]+\\.dcm$',
        '/*'
    )                                               AS "SeriesAWSURL"
FROM
    IDC.IDC_V17.DICOM_PIVOT
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
    "SeriesDate",
    "SeriesDescription",
    "SeriesNumber",
    "BodyPartExamined",
    "PatientAge",
    "PatientSex"
ORDER BY
    "StudyDate" ASC,
    "SeriesInstanceUID" ASC;