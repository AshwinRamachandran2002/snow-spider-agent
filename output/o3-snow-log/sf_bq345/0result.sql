SELECT 
    "collection_id"                                    AS "COLLECTION_ID",
    "StudyInstanceUID"                                 AS "STUDY_INSTANCE_UID",
    "SeriesInstanceUID"                                AS "SERIES_INSTANCE_UID",
    'https://viewer.imaging.datacommons.cancer.gov/viewer/' 
        || "StudyInstanceUID"                          AS "VIEWER_URL",
    ROUND(SUM(COALESCE("instance_size",0))/1024 , 2)   AS "TOTAL_SIZE_KB"
FROM   IDC.IDC_V17."DICOM_ALL"
WHERE  "Modality" IN ('SEG','RTSTRUCT')
  AND  "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND  ( "ReferencedSeriesSequence" IS NULL 
         OR "ReferencedSeriesSequence" = '[]')
  AND  ( "ReferencedImageSequence"  IS NULL 
         OR "ReferencedImageSequence"  = '[]')
  AND  ( "SourceImageSequence"      IS NULL 
         OR "SourceImageSequence"      = '[]')
GROUP BY 
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY 
    "TOTAL_SIZE_KB" DESC NULLS LAST;