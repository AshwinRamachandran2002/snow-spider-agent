SELECT
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    ROUND(SUM("instance_size")/1024.0, 1)               AS "size_kb",
    'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID" 
                                                       AS "viewer_url"
FROM   IDC.IDC_V17.DICOM_ALL
WHERE  "Modality" IN ('SEG', 'RTSTRUCT')
  AND  "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND  "ReferencedSeriesSequence" = '[]'
  AND  "ReferencedImageSequence"  = '[]'
  AND  "SourceImageSequence"      = '[]'
GROUP  BY
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "size_kb" DESC NULLS LAST;