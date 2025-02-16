-- Task: In the "qin_prostate_repeatability" collection, please provide the distinct StudyInstanceUIDs for studies that include T2-weighted axial MR imaging.

SELECT DISTINCT
  "dicom_all_mr"."StudyInstanceUID"
FROM
  "IDC"."IDC_V17"."DICOM_ALL" AS "dicom_all_mr"
WHERE
  "Modality" = 'MR'
  AND "collection_id" = 'qin_prostate_repeatability'
  AND CONTAINS("SeriesDescription", 'T2 Weighted Axial');