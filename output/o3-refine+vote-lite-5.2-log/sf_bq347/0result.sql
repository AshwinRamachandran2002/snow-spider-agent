WITH mr_instances AS (   -- SOP instances in the specified MR series
    SELECT 
        "SOPInstanceUID",
        "Modality"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
seg_sops AS (            -- segmentation SOPs referencing that MR series
    SELECT 
        "SOPInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
seg_instances AS (       -- modalities for those segmentation SOPs
    SELECT 
        d."SOPInstanceUID",
        d."Modality"
    FROM IDC.IDC_V17.DICOM_ALL d
    JOIN seg_sops s
      ON d."SOPInstanceUID" = s."SOPInstanceUID"
)
SELECT 
    "Modality",
    COUNT(*) AS "Num_SOP_Instances"
FROM (
    SELECT * FROM mr_instances
    UNION ALL
    SELECT * FROM seg_instances
) all_inst
GROUP BY "Modality"
ORDER BY "Num_SOP_Instances" DESC NULLS LAST, "Modality"
LIMIT 1;