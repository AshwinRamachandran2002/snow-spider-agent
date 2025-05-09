SELECT
    "collection_id"                                    AS "CollectionID",
    "PatientID",
    "PatientSex",
    "PatientAge",
    "StudyInstanceUID",
    "StudyDate",
    "StudyDescription",
    "SeriesInstanceUID",
    "SeriesDate",
    "SeriesDescription",
    "BodyPartExamined",
    "Modality",
    MIN("series_aws_url")                              AS "Series_AWS_URL",
    ROUND(SUM("instance_size") / 1000000, 2)           AS "Series_Size_MB"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
        "PatientSex" = 'M'
    AND TO_NUMBER(REGEXP_SUBSTR("PatientAge", '\\d+')) = 18
    AND "BodyPartExamined" = 'MEDIASTINUM'
    AND "StudyDate" > '2014-09-01'
GROUP BY
    "collection_id",
    "PatientID",
    "PatientSex",
    "PatientAge",
    "StudyInstanceUID",
    "StudyDate",
    "StudyDescription",
    "SeriesInstanceUID",
    "SeriesDate",
    "SeriesDescription",
    "BodyPartExamined",
    "Modality"
ORDER BY
    "CollectionID",
    "PatientID",
    "SeriesInstanceUID";