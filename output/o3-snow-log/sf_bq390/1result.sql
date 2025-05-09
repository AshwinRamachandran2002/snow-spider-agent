WITH t2_series AS (   -- studies with any T2-weighted MR series
    SELECT DISTINCT "StudyInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'qin_prostate_repeatability'
      AND "Modality" = 'MR'
      AND ( "SeriesDescription" ILIKE '%t2%' 
            OR "ProtocolName"   ILIKE '%t2%' )
),
peripheral_seg AS (   -- studies that have a segmentation of the Peripheral zone
    SELECT DISTINCT img."StudyInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS seg
    JOIN IDC.IDC_V17.DICOM_ALL   img
          ON img."SeriesInstanceUID" = seg."SeriesInstanceUID"
    WHERE img."collection_id" = 'qin_prostate_repeatability'
      AND seg."SegmentedPropertyType"::STRING ILIKE '%peripheral%'
)
/* studies that satisfy both conditions */
SELECT DISTINCT t2_series."StudyInstanceUID"
FROM   t2_series
JOIN   peripheral_seg USING ("StudyInstanceUID")
ORDER BY "StudyInstanceUID";