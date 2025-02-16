-- Task: Retrieve the collection IDs, study IDs, series IDs, viewer URLs (formatted as 'https://viewer.imaging.datacommons.cancer.gov/viewer/' followed by the StudyInstanceUID), and instance sizes of DICOM files with SEG or RTSTRUCT modalities and SOP Class UID '1.2.840.10008.5.1.4.1.1.66.4', which have no references to other series, images, or sources. Limit the results to 100 records.

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
LIMIT 100;