SELECT
  "collection_name",
  "StudyInstanceUID",
  "SeriesInstanceUID",
  ROUND(SUM("instance_size") / 1024, 4) AS "total_size_kb",
  'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID" AS "viewer_url"
FROM
  IDC.IDC_V17.DICOM_ALL
WHERE
  "Modality" IN ('SEG', 'RTSTRUCT')
  AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND (
    "ReferencedSeriesSequence" IS NULL OR ARRAY_SIZE("ReferencedSeriesSequence") = 0
  )
  AND (
    "SourceImageSequence" IS NULL OR ARRAY_SIZE("SourceImageSequence") = 0
  )
  AND "ReferencedSOPInstanceUID" IS NULL
  AND "ReferencedSOPClassUID" IS NULL
GROUP BY
  "collection_name",
  "StudyInstanceUID",
  "SeriesInstanceUID"
ORDER BY
  "total_size_kb" DESC NULLS LAST
LIMIT 1000;