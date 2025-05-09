SELECT
    "collection_id",
    "StudyInstanceUID"  AS "study_id",
    "SeriesInstanceUID" AS "series_id",
    ROUND(SUM("instance_size")/1024, 4) AS "size_kb",
    'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID" AS "viewer_url"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    "Modality" IN ('SEG', 'RTSTRUCT')
    AND "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'                 -- Segmentation Storage
    -- exclude objects that reference other series, images, or sources
    AND ( "ReferencedSeriesSequence" IS NULL OR TRIM("ReferencedSeriesSequence") = '[]')
    AND ( "ReferencedImageSequence"  IS NULL OR TRIM("ReferencedImageSequence")  = '[]')
    AND ( "SourceImageSequence"      IS NULL OR TRIM("SourceImageSequence")      = '[]')
    AND "instance_size" IS NOT NULL
GROUP BY
    "collection_id",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "size_kb" DESC NULLS LAST;