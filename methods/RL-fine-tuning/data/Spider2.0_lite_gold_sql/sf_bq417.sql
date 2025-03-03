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
  CONCAT('s3://', SPLIT_PART("aws_url", '/', 3), '/', "SeriesInstanceUID", '/*') AS "SeriesAWSURL",
  ROUND(SUM("instance_size") / 1000000.0, 4) AS "TotalSizeMB"
FROM IDC.IDC_V17.DICOM_ALL
WHERE
  "PatientSex" = 'M'
  AND SUBSTR("PatientAge", 1, 3) = '018'
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
  CONCAT('s3://', SPLIT_PART("aws_url", '/', 3), '/', "SeriesInstanceUID", '/*')