-- Task: Calculate the total size, in kilobytes, of DICOM image files with modalities 'SEG' or 'RTSTRUCT' and SOP Class UID '1.2.840.10008.5.1.4.1.1.66.4', grouped by "collection_id", "StudyInstanceUID", and "SeriesInstanceUID", where the "ReferencedSeriesSequence", "ReferencedImageSequence", and "SourceImageSequence" arrays are empty (i.e., have size zero). Also, provide a viewer URL by concatenating 'https://viewer.imaging.datacommons.cancer.gov/viewer/' with the "StudyInstanceUID". List the groups sorted by total size in kilobytes from largest to smallest.

WITH seg_rtstruct AS (
  SELECT
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    CONCAT('https://viewer.imaging.datacommons.cancer.gov/viewer/', "StudyInstanceUID") AS "viewer_url",
    "instance_size"
  FROM
    "IDC"."IDC_V17"."DICOM_ALL"
  WHERE
    "Modality" IN ('SEG', 'RTSTRUCT')
    AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
    AND ARRAY_SIZE("ReferencedSeriesSequence") = 0
    AND ARRAY_SIZE("ReferencedImageSequence") = 0
    AND ARRAY_SIZE("SourceImageSequence") = 0
)

SELECT
  seg_rtstruct."collection_id",
  seg_rtstruct."SeriesInstanceUID",
  seg_rtstruct."StudyInstanceUID",
  seg_rtstruct."viewer_url",
  SUM(seg_rtstruct."instance_size") / 1024 AS "collection_size_KB"
FROM
  seg_rtstruct
GROUP BY
  seg_rtstruct."collection_id",
  seg_rtstruct."SeriesInstanceUID",
  seg_rtstruct."StudyInstanceUID",
  seg_rtstruct."viewer_url"
ORDER BY
  "collection_size_KB" DESC;