SELECT
        "collection_id",
        CONCAT('https://viewer.imaging.datacommons.cancer.gov/viewer/', "StudyInstanceUID") AS "viewer_url",
        "SeriesInstanceUID",
        ROUND(SUM("instance_size") / 1024, 2)                                              AS "size_kb"
FROM    IDC.IDC_V17.DICOM_ALL
WHERE  (
          "Modality" IN ('SEG','RTSTRUCT')
          OR "SOPClassUID" = '1.2.840.10008.5.1.4.1.1.66.4'
       )
  AND  ( "ReferencedSeriesSequence" IS NULL  OR CAST("ReferencedSeriesSequence"  AS STRING) = '[]' )
  AND  ( "ReferencedImageSequence"  IS NULL  OR CAST("ReferencedImageSequence"   AS STRING) = '[]' )
  AND  ( "SourceImageSequence"      IS NULL  OR CAST("SourceImageSequence"       AS STRING) = '[]' )
GROUP BY
        "collection_id",
        "StudyInstanceUID",
        "SeriesInstanceUID"
ORDER BY
        "size_kb" DESC NULLS LAST;