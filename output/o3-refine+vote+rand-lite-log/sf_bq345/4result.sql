SELECT
    "collection_id"                                     AS "collection_id",
    "StudyInstanceUID"                                  AS "study_instance_uid",
    "SeriesInstanceUID"                                 AS "series_instance_uid",
    ROUND(SUM(COALESCE("instance_size",0))/1024, 2)     AS "size_kb",
    CONCAT('https://viewer.imaging.datacommons.cancer.gov/viewer/', 
           "StudyInstanceUID")                          AS "viewer_url"
FROM
    "IDC"."IDC_V17"."DICOM_ALL"
WHERE
      "Modality" IN ('SEG','RTSTRUCT')
  AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND ( "ReferencedSeriesSequence" IS NULL  OR "ReferencedSeriesSequence" = '[]')
  AND ( "ReferencedImageSequence"  IS NULL  OR "ReferencedImageSequence"  = '[]')
  AND ( "SourceImageSequence"      IS NULL  OR "SourceImageSequence"      = '[]')
GROUP BY
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "size_kb" DESC NULLS LAST;