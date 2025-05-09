SELECT
    "collection_id"                                     AS "CollectionID",
    "StudyInstanceUID"                                  AS "StudyInstanceUID",
    "SeriesInstanceUID"                                 AS "SeriesInstanceUID",
    ROUND(SUM("instance_size") / 1024, 2)               AS "TotalSizeKB",
    'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID"
                                                       AS "ViewerURL"
FROM IDC.IDC_V17.DICOM_ALL
WHERE "Modality" IN ('SEG', 'RTSTRUCT')
  AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND COALESCE(TO_VARCHAR("ReferencedSeriesSequence"),  '[]') = '[]'
  AND COALESCE(TO_VARCHAR("ReferencedImageSequence"),   '[]') = '[]'
  AND COALESCE(TO_VARCHAR("SourceImageSequence"),       '[]') = '[]'
GROUP BY
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "TotalSizeKB" DESC NULLS LAST;