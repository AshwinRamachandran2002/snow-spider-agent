SELECT
    "PatientID",
    "PatientSex",
    "PatientAge",
    "StudyInstanceUID",
    "StudyDate",
    "SeriesInstanceUID",
    "SeriesDescription",
    "Modality",
    "Manufacturer",
    "ManufacturerModelName",
    MIN("aws_url")                                      AS "series_aws_url_example",   -- one representative object URL
    ROUND(SUM("instance_size")/1000000, 4)              AS "series_size_mb"            -- total size in megabytes
FROM
    "IDC"."IDC_V17"."DICOM_ALL"
WHERE
    "PatientAge"          ILIKE '018%'            -- exactly 18 years old
    AND "PatientSex"      = 'M'                   -- male patients
    AND "BodyPartExamined" ILIKE '%MEDIASTINUM%'  -- mediastinum examinations
    AND "StudyDate"       > '2014-09-01'          -- study date strictly after 2014-09-01
GROUP BY
    "PatientID",
    "PatientSex",
    "PatientAge",
    "StudyInstanceUID",
    "StudyDate",
    "SeriesInstanceUID",
    "SeriesDescription",
    "Modality",
    "Manufacturer",
    "ManufacturerModelName"
ORDER BY
    "series_size_mb" DESC NULLS LAST;