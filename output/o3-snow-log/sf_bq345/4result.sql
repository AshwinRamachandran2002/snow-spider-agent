SELECT
  "collection_id"                                     AS "CollectionID",
  "StudyInstanceUID"                                  AS "StudyInstanceUID",
  "SeriesInstanceUID"                                 AS "SeriesInstanceUID",
  ROUND(SUM("instance_size") / 1024.0, 2)             AS "SizeKB",
  CONCAT('https://viewer.imaging.datacommons.cancer.gov/viewer/', "StudyInstanceUID")
                                                     AS "viewer_url"
FROM   IDC.IDC_V17.DICOM_ALL
WHERE  "Modality" IN ('SEG','RTSTRUCT')
  AND  "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  /* ensure no references to other series, images, or sources */
  AND  COALESCE("ReferencedSeriesSequence"        ,'[]') = '[]'
  AND  COALESCE("ReferencedImageSequence"         ,'[]') = '[]'
  AND  COALESCE("SourceImageSequence"             ,'[]') = '[]'
  AND  COALESCE("ReferencedImageEvidenceSequence" ,'[]') = '[]'
GROUP BY
  "collection_id",
  "StudyInstanceUID",
  "SeriesInstanceUID"
ORDER BY
  "SizeKB" DESC NULLS LAST;