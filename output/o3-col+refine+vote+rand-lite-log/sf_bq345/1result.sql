/*  Size (in KB) of standalone SEG/RTSTRUCT objects that use
    SOP Class UID 1.2.840.10008.5.1.4.1.1.66.4,
    grouped by collection, study, and series.                        */

SELECT
    agg."collection_id",
    agg."StudyInstanceUID"                    AS "study_id",
    'https://viewer.imaging.datacommons.cancer.gov/viewer/' 
        || agg."StudyInstanceUID"             AS "viewer_url",
    agg."SeriesInstanceUID"                   AS "series_id",
    agg."total_size_kb"
FROM (
    SELECT
        "collection_id",
        "StudyInstanceUID",
        "SeriesInstanceUID",
        ROUND(SUM("instance_size") / 1024.0, 2) AS "total_size_kb"
    FROM  IDC.IDC_V17."DICOM_ALL"
    WHERE "Modality"     IN ('SEG','RTSTRUCT')
      AND "SOPClassUID"  =  '1.2.840.10008.5.1.4.1.1.66.4'
      AND ( ( "ReferencedSeriesSequence" IS NULL 
              OR "ReferencedSeriesSequence" = '[]' )
         AND ( "ReferencedImageSequence"  IS NULL 
              OR "ReferencedImageSequence"  = '[]' )
         AND ( "SourceImageSequence"      IS NULL 
              OR "SourceImageSequence"      = '[]' ) )
    GROUP BY
        "collection_id",
        "StudyInstanceUID",
        "SeriesInstanceUID"
) agg
ORDER BY
    agg."total_size_kb" DESC NULLS LAST;