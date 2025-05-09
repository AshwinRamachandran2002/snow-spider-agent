SELECT
  "collection_name",
  "StudyInstanceUID",
  'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID" AS "viewer_url",
  "SeriesInstanceUID",
  ROUND(SUM("instance_size") / 1024.0, 2) AS "total_size_kB"
FROM
  IDC.IDC_V17.DICOM_ALL
WHERE
      "Modality"   IN ('SEG', 'RTSTRUCT')
  AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND (
        ("ReferencedSeriesSequence" IS NULL OR "ReferencedSeriesSequence" = '[]')
    AND ("ReferencedImageSequence"  IS NULL OR "ReferencedImageSequence"  = '[]')
    AND ("SourceImageSequence"      IS NULL OR "SourceImageSequence"      = '[]')
  )
GROUP BY
  "collection_name",
  "StudyInstanceUID",
  "SeriesInstanceUID"
ORDER BY
  "total_size_kB" DESC NULLS LAST;