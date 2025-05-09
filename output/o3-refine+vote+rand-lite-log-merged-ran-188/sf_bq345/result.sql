SELECT
    "collection_id"                            AS "CollectionID",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    ROUND(SUM("instance_size")/1024,2)         AS "Size_KB",
    CONCAT('https://viewer.imaging.datacommons.cancer.gov/viewer/',"StudyInstanceUID") 
                                               AS "viewer_url"
FROM   "IDC"."IDC_V17"."DICOM_ALL"
WHERE  "Modality" IN ('SEG','RTSTRUCT')
  AND  "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  -- ensure no references to other series/images/sources
  AND  ( "ReferencedSeriesSequence"            IS NULL OR "ReferencedSeriesSequence"            = '[]')
  AND  ( "ReferencedImageSequence"             IS NULL OR "ReferencedImageSequence"             = '[]')
  AND  ( "SourceImageSequence"                 IS NULL OR "SourceImageSequence"                 = '[]')
  AND  ( "ReferencedRawDataSequence"           IS NULL OR "ReferencedRawDataSequence"           = '[]')
  AND  ( "SourceIrradiationEventSequence"      IS NULL OR "SourceIrradiationEventSequence"      = '[]')
  AND  ( "SourcePatientGroupIdentificationSequence" IS NULL OR "SourcePatientGroupIdentificationSequence" = '[]')
GROUP BY
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "Size_KB" DESC NULLS LAST;