SELECT
    "collection_id"                                   AS "collection",
    "StudyInstanceUID"                                AS "study_id",
    "SeriesInstanceUID"                               AS "series_id",
    CONCAT('https://viewer.imaging.datacommons.cancer.gov/viewer/', "StudyInstanceUID") 
                                                     AS "viewer_url",
    ROUND(SUM("instance_size") / 1024.0, 2)          AS "size_kb"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
        "Modality" IN ('SEG', 'RTSTRUCT')
    AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
    -- exclude objects that reference other data
    AND ( "ReferencedSeriesSequence" IS NULL OR "ReferencedSeriesSequence" = '[]' )
    AND ( "ReferencedImageSequence"  IS NULL OR "ReferencedImageSequence"  = '[]' )
    AND ( "SourceImageSequence"      IS NULL OR "SourceImageSequence"      = '[]' )
    AND ( "ReferencedRawDataSequence" IS NULL OR "ReferencedRawDataSequence" = '[]' )
    AND   "ReferencedSOPInstanceUID"        IS NULL
    AND   "ReferencedSOPInstanceUIDInFile"  IS NULL
GROUP BY
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "size_kb" DESC NULLS LAST,
    "collection",
    "study_id",
    "series_id";