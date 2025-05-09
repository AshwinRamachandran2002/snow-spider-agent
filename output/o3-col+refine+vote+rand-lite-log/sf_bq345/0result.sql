SELECT
  "collection_id"                          AS "Collection",
  "StudyInstanceUID"                       AS "Study_ID",
  "SeriesInstanceUID"                      AS "Series_ID",
  ROUND(SUM("instance_size")/1024.0, 2)    AS "Total_Size_KB",
  'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID"
                                           AS "Viewer_URL"
FROM IDC.IDC_V17.DICOM_ALL
WHERE "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'      -- Segmentation Storage
  AND "Modality" IN ('SEG','RTSTRUCT')                    -- requested modalities
  AND "ReferencedSeriesSequence"  = '[]'                  -- no external references
  AND "ReferencedImageSequence"   = '[]'
  AND "SourceImageSequence"       = '[]'
  AND "ReferencedRawDataSequence" = '[]'
GROUP BY
  "collection_id",
  "StudyInstanceUID",
  "SeriesInstanceUID"
ORDER BY
  "Total_Size_KB" DESC NULLS LAST;