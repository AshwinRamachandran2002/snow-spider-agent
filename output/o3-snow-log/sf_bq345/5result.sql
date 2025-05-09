SELECT
  "collection_id",
  "StudyInstanceUID"  AS "study_id",
  "SeriesInstanceUID" AS "series_id",
  'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID"  AS "viewer_url",
  ROUND(SUM("instance_size") / 1024, 2)                             AS "total_size_kb"
FROM
  IDC.IDC_V17.DICOM_ALL
WHERE
      "Modality"    IN ('SEG', 'RTSTRUCT')
  AND "SOPClassUID" =  '1.2.840.10008.5.1.4.1.1.66.4'
  AND ( "ReferencedSeriesSequence" IS NULL  OR TO_VARCHAR("ReferencedSeriesSequence")  = '[]')
  AND ( "ReferencedImageSequence"  IS NULL  OR TO_VARCHAR("ReferencedImageSequence")   = '[]')
  AND ( "SourceImageSequence"      IS NULL  OR TO_VARCHAR("SourceImageSequence")       = '[]')
GROUP BY
  "collection_id",
  "StudyInstanceUID",
  "SeriesInstanceUID"
ORDER BY
  "total_size_kb" DESC NULLS LAST;