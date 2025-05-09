SELECT
    "collection_name"                                   AS "Collection",
    "StudyInstanceUID"                                  AS "Study_ID",
    "SeriesInstanceUID"                                 AS "Series_ID",
    'https://viewer.imaging.datacommons.cancer.gov/viewer/' || "StudyInstanceUID" 
                                                        AS "Viewer_URL",
    ROUND(SUM("instance_size")/1024, 2)                 AS "Total_Size_KB"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
    AND "Modality" IN ('SEG', 'RTSTRUCT')
    AND ( "ReferencedImageSequence"         IS NULL OR "ReferencedImageSequence"         = '[]')
    AND ( "ReferencedSeriesSequence"        IS NULL OR "ReferencedSeriesSequence"        = '[]')
    AND ( "SourceImageSequence"             IS NULL OR "SourceImageSequence"             = '[]')
    AND ( "ReferencedRawDataSequence"       IS NULL OR "ReferencedRawDataSequence"       = '[]')
    AND ( "SourceIrradiationEventSequence"  IS NULL OR "SourceIrradiationEventSequence"  = '[]')
GROUP BY
    "collection_name",
    "StudyInstanceUID",
    "SeriesInstanceUID"
ORDER BY
    "Total_Size_KB" DESC NULLS LAST;