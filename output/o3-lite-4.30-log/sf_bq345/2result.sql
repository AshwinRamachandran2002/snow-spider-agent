SELECT
    "collection_name"                    AS "collection_id",
    "StudyInstanceUID"                   AS "study_instance_uid",
    "SeriesInstanceUID"                  AS "series_instance_uid",
    'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID"
                                         AS "viewer_url",
    ROUND(SUM("instance_size") / 1024, 4) AS "size_kb"
FROM IDC.IDC_V17.DICOM_ALL
WHERE (
        ("Modality" = 'SEG'      AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4')
     OR ("Modality" = 'RTSTRUCT')
      )
  AND ( "ReferencedSeriesSequence"                       IS NULL OR "ReferencedSeriesSequence"::STRING                       = '[]' )
  AND ( "ReferencedImageSequence"                        IS NULL OR "ReferencedImageSequence"::STRING                        = '[]' )
  AND ( "SourceImageSequence"                            IS NULL OR "SourceImageSequence"::STRING                            = '[]' )
  AND ( "ReferencedImageEvidenceSequence"                IS NULL OR "ReferencedImageEvidenceSequence"::STRING                = '[]' )
  AND ( "StudiesContainingOtherReferencedInstancesSequence" IS NULL OR "StudiesContainingOtherReferencedInstancesSequence"::STRING = '[]' )
GROUP BY
    "collection_name",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "size_kb" DESC NULLS LAST,
    "collection_id",
    "study_instance_uid",
    "series_instance_uid";