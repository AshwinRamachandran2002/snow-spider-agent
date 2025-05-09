SELECT
  dp."collection_id" AS "Collection_ID",
  dp."PatientID" AS "Patient_ID",
  dp."StudyInstanceUID",
  dp."StudyDate",
  dp."SeriesInstanceUID",
  dp."SeriesDate",
  dp."SeriesDescription",
  dp."Modality",
  dp."Manufacturer",
  dp."ManufacturerModelName",
  ROUND(SUM(dp."instance_size") / 1000000, 4) AS "Series_Size_MB",
  CONCAT('s3://idc-open-data/', dp."SeriesInstanceUID", '/*') AS "Series_AWS_URL"
FROM
  IDC.IDC_V17.DICOM_PIVOT dp
WHERE
  dp."PatientSex" = 'M'
  AND TO_NUMBER(REGEXP_SUBSTR(dp."PatientAge", '^[0-9]+')) > 60
  AND dp."BodyPartExamined" = 'MEDIASTINUM'
  AND dp."StudyDate" > '2014-09-01'
GROUP BY
  dp."collection_id",
  dp."PatientID",
  dp."StudyInstanceUID",
  dp."StudyDate",
  dp."SeriesInstanceUID",
  dp."SeriesDate",
  dp."SeriesDescription",
  dp."Modality",
  dp."Manufacturer",
  dp."ManufacturerModelName";