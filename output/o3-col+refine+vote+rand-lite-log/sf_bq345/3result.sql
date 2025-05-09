SELECT
  "collection_id"                                                AS "COLLECTION_ID",
  "StudyInstanceUID"                                             AS "STUDY_ID",
  "SeriesInstanceUID"                                            AS "SERIES_ID",
  ROUND(SUM("instance_size")/1024,2)                             AS "TOTAL_KB",
  'https://viewer.imaging.datacommons.cancer.gov/viewer/' ||
    "StudyInstanceUID"                                           AS "VIEWER_URL"
FROM IDC.IDC_V17."DICOM_ALL"
WHERE
      "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND ("Modality" ILIKE '%SEG%' OR "Modality" ILIKE '%RTSTRUCT%')
  AND (   ("ReferencedSeriesSequence" IS NULL OR "ReferencedSeriesSequence" = '[]')
       AND ("ReferencedImageSequence"  IS NULL OR "ReferencedImageSequence"  = '[]')
       AND ("SourceImageSequence"      IS NULL OR "SourceImageSequence"      = '[]') )
GROUP BY
  "collection_id",
  "StudyInstanceUID",
  "SeriesInstanceUID"
ORDER BY
  "TOTAL_KB" DESC NULLS LAST;