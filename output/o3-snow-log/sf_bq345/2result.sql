SELECT
  "collection_id"                           AS "CollectionID",
  "StudyInstanceUID"                        AS "StudyInstanceUID",
  "SeriesInstanceUID"                       AS "SeriesInstanceUID",
  CONCAT('https://viewer.imaging.datacommons.cancer.gov/viewer/', 
         "StudyInstanceUID")                AS "viewer_url",
  ROUND(SUM("instance_size")/1024, 4)       AS "total_size_kb"
FROM  IDC.IDC_V17.DICOM_ALL
WHERE "Modality"      IN ('SEG','RTSTRUCT')
  AND "SOPClassUID"   = '1.2.840.10008.5.1.4.1.1.66.4'
  -- keep only instances without any referenced series/images/sources
  AND ( "ReferencedSeriesSequence" IS NULL OR "ReferencedSeriesSequence" = '[]')
  AND ( "ReferencedImageSequence"  IS NULL OR "ReferencedImageSequence"  = '[]')
  AND ( "SourceImageSequence"      IS NULL OR "SourceImageSequence"      = '[]')
  AND ( "ReferencedRawDataSequence" IS NULL OR "ReferencedRawDataSequence" = '[]')
GROUP BY
  "collection_id",
  "StudyInstanceUID",
  "SeriesInstanceUID"
ORDER BY
  "total_size_kb" DESC NULLS LAST;