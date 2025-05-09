SELECT
    "collection_id"                                    AS collection_id,
    "StudyInstanceUID"                                 AS study_instance_uid,
    "SeriesInstanceUID"                                AS series_instance_uid,
    'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID"
                                                      AS viewer_url,
    ROUND(SUM("instance_size") / 1024, 4)              AS size_kb
FROM IDC.IDC_V17.DICOM_ALL
WHERE "Modality" IN ('SEG', 'RTSTRUCT')
  AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
  AND COALESCE(ARRAY_SIZE("ReferencedSeriesSequence"), 0)  = 0
  AND COALESCE(ARRAY_SIZE("ReferencedImageSequence"), 0)   = 0
  AND COALESCE(ARRAY_SIZE("SourceImageSequence"), 0)       = 0
  AND COALESCE(ARRAY_SIZE("DerivationImageSequence"), 0)   = 0
GROUP BY
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    size_kb DESC NULLS LAST;