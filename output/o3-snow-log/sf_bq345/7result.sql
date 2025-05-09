SELECT
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID",
    ROUND(SUM("instance_size") / 1024.0 , 2)             AS "size_kb",
    'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID" AS "viewer_url"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
        "Modality" IN ('SEG','RTSTRUCT')
    AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
    /* ensure there are no references to other series, images, or sources */
    AND ( "ReferencedSeriesSequence" IS NULL OR "ReferencedSeriesSequence" = '[]' )
    AND ( "ReferencedImageSequence"  IS NULL OR "ReferencedImageSequence"  = '[]' )
    AND ( "SourceImageSequence"      IS NULL OR "SourceImageSequence"      = '[]' )
    AND ( "SourceIrradiationEventSequence" IS NULL OR "SourceIrradiationEventSequence" = '[]' )
GROUP BY
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "size_kb" DESC NULLS LAST;