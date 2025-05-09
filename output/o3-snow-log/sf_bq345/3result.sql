SELECT 
    DA."collection_id"                                   AS "CollectionID",
    DA."StudyInstanceUID",
    DA."SeriesInstanceUID",
    ROUND(SUM(DA."instance_size")/1024.0, 2)             AS "TotalSizeKB",
    CONCAT('https://viewer.imaging.datacommons.cancer.gov/viewer/', 
           DA."StudyInstanceUID")                        AS "ViewerURL"
FROM 
    IDC.IDC_V17.DICOM_ALL  AS DA
WHERE 
      DA."Modality" IN ('SEG','RTSTRUCT')
  AND DA."SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND (DA."ReferencedSeriesSequence" IS NULL OR DA."ReferencedSeriesSequence" = '[]')
  AND (DA."ReferencedImageSequence"  IS NULL OR DA."ReferencedImageSequence"  = '[]')
  AND (DA."SourceImageSequence"      IS NULL OR DA."SourceImageSequence"      = '[]')
GROUP BY 
    DA."collection_id",
    DA."StudyInstanceUID",
    DA."SeriesInstanceUID"
ORDER BY 
    "TotalSizeKB" DESC NULLS LAST;