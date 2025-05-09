SELECT
    "collection_id",
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "StudyDescription",
    "SeriesInstanceUID",
    "SeriesDate",
    "SeriesDescription",
    "SeriesNumber",
    "Modality",
    "Manufacturer",
    "ManufacturerModelName",
    "series_aws_url" AS "SeriesAWSURL",
    SUM("instance_size") / 1000000.0 AS "TotalSizeMB"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    SUBSTR("PatientAge", 1, 3) = '018'
    AND "PatientSex" = 'M'
    AND "BodyPartExamined" = 'MEDIASTINUM'
    AND "StudyDate" > '2014-09-01'
GROUP BY
    "collection_id",
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "StudyDescription",
    "SeriesInstanceUID",
    "SeriesDate",
    "SeriesDescription",
    "SeriesNumber",
    "Modality",
    "Manufacturer",
    "ManufacturerModelName",
    "series_aws_url";