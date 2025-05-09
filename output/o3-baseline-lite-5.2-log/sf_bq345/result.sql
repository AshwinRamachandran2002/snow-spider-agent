SELECT 
    "collection_id"                                                    AS "collection_id",
    "StudyInstanceUID"                                                 AS "study_id",
    "SeriesInstanceUID"                                                AS "series_id",
    ROUND(SUM("instance_size")/1024,2)                                 AS "size_kb",
    CONCAT('https://viewer.imaging.datacommons.cancer.gov/viewer/', 
           "StudyInstanceUID")                                         AS "viewer_url"
FROM   IDC.IDC_V17.DICOM_ALL
WHERE  "Modality" IN ('SEG','RTSTRUCT')
  AND  "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  -- no references to other series, images, or sources
  AND  "ReferencedSeriesSequence" = '[]'
  AND  "ReferencedImageSequence"  = '[]'
  AND  "SourceImageSequence"      = '[]'
GROUP  BY 
       "collection_id",
       "StudyInstanceUID",
       "SeriesInstanceUID"
ORDER  BY 
       "size_kb" DESC NULLS LAST;