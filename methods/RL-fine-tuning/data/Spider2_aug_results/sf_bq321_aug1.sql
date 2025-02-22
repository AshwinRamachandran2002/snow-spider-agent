-- Task: How many unique StudyInstanceUIDs are there from the 'DWI' series in the 'qin_prostate_repeatability' collection?
SELECT 
  COUNT(DISTINCT "StudyInstanceUID") AS "total_count"
FROM 
  IDC.IDC_V17.DICOM_ALL
WHERE 
  "collection_id" = 'qin_prostate_repeatability'
  AND "SeriesDescription" = 'DWI';