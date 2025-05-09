WITH
/* segmentation series that reference the specified MR series */
seg_series AS (
    SELECT DISTINCT "SeriesInstanceUID"
    FROM IDC.IDC_V17."SEGMENTATIONS"
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
/* union of all SOP instances in the MR series and its associated segmentation series */
union_instances AS (
    /* SOPs in the specified MR series */
    SELECT "Modality",
           "SOPInstanceUID"
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    
    UNION ALL
    
    /* SOPs in segmentation series associated with that MR series */
    SELECT da."Modality",
           da."SOPInstanceUID"
    FROM IDC.IDC_V17."DICOM_ALL" da
    JOIN seg_series ss
      ON da."SeriesInstanceUID" = ss."SeriesInstanceUID"
)
/* determine modality with the greatest number of SOP instances */
SELECT "Modality",
       COUNT(*) AS "SOPInstanceCount"
FROM union_instances
GROUP BY "Modality"
ORDER BY "SOPInstanceCount" DESC NULLS LAST
LIMIT 1;