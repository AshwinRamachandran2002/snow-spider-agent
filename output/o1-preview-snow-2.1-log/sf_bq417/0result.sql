SELECT 
    "collection_id" AS "Collection_ID",
    "PatientID" AS "Patient_ID",
    "StudyInstanceUID",
    "StudyDate",
    "SeriesInstanceUID",
    "SeriesDate",
    "SeriesDescription",
    "Modality",
    "Manufacturer",
    "ManufacturerModelName",
    ROUND(SUM("instance_size") / 1000000, 4) AS "Series_Size_MB",
    's3://idc-open-data/' || "SeriesInstanceUID" || '/*' AS "Series_AWS_URL"
FROM "IDC"."IDC_V17"."DICOM_PIVOT"
WHERE 
    "PatientSex" = 'M' 
    AND TRY_TO_NUMBER(SUBSTRING("PatientAge", 1, 3)) >= 60 
    AND SUBSTRING("PatientAge", 4, 1) = 'Y'
    AND "StudyDate" >= '2014-09-01'
    AND "BodyPartExamined" ILIKE '%mediastinum%'
GROUP BY 
    "collection_id",
    "PatientID",
    "StudyInstanceUID",
    "StudyDate",
    "SeriesInstanceUID",
    "SeriesDate",
    "SeriesDescription",
    "Modality",
    "Manufacturer",
    "ManufacturerModelName"
ORDER BY "Series_Size_MB" DESC NULLS LAST;