WITH
slice_thickness_diff AS (
  SELECT "PatientID",
         MAX(CAST("SliceThickness" AS FLOAT)) - MIN(CAST("SliceThickness" AS FLOAT)) AS slice_thickness_difference
  FROM IDC.IDC_V17.DICOM_ALL
  WHERE UPPER("collection_name") = 'NLST'
    AND UPPER("Modality") = 'CT'
    AND "SliceThickness" IS NOT NULL
    AND "SliceThickness" != ''
  GROUP BY "PatientID"
),
top_slice_patients AS (
  SELECT "PatientID"
  FROM slice_thickness_diff
  ORDER BY slice_thickness_difference DESC NULLS LAST
  LIMIT 3
),
exposure_diff AS (
  SELECT "PatientID",
         MAX(CAST("Exposure" AS FLOAT)) - MIN(CAST("Exposure" AS FLOAT)) AS exposure_difference
  FROM IDC.IDC_V17.DICOM_ALL
  WHERE UPPER("collection_name") = 'NLST'
    AND UPPER("Modality") = 'CT'
    AND "Exposure" IS NOT NULL
    AND "Exposure" != ''
  GROUP BY "PatientID"
),
top_exposure_patients AS (
  SELECT "PatientID"
  FROM exposure_diff
  ORDER BY exposure_difference DESC NULLS LAST
  LIMIT 3
),
all_top_patients AS (
  SELECT "PatientID" FROM top_slice_patients
  UNION
  SELECT "PatientID" FROM top_exposure_patients
),
patient_series_sizes AS (
  SELECT "PatientID", "SeriesInstanceUID", SUM("instance_size") / (1024 * 1024) AS series_size_mib
  FROM IDC.IDC_V17.DICOM_ALL
  WHERE UPPER("collection_name") = 'NLST'
    AND UPPER("Modality") = 'CT'
    AND "PatientID" IN (SELECT "PatientID" FROM all_top_patients)
  GROUP BY "PatientID", "SeriesInstanceUID"
),
average_series_sizes AS (
  SELECT "PatientID", ROUND(AVG(series_size_mib), 4) AS average_series_size_mib
  FROM patient_series_sizes
  GROUP BY "PatientID"
)
SELECT *
FROM average_series_sizes
ORDER BY "PatientID";