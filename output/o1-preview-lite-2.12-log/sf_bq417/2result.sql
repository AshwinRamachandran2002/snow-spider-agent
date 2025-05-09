SELECT
  "collection_id" AS "CollectionID",
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
  CONCAT('s3://', "aws_bucket", '/', "SeriesInstanceUID", '/*') AS "SeriesAWSURL",
  ROUND(SUM("instance_size") / 1000000, 4) AS "TotalSizeMB"
FROM "IDC"."IDC_V17"."DICOM_PIVOT"
WHERE "PatientSex" = 'M'
  AND TRY_TO_NUMBER(TRIM(TRANSLATE("PatientAge", 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', ''))) = 18
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
  "aws_bucket";