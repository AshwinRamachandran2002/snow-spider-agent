WITH
-- 1.  SOPInstanceUIDs of segmentation objects that reference the target MR series
seg_sops AS (
    SELECT DISTINCT 
        "SOPInstanceUID"
    FROM IDC.IDC_V17."SEGMENTATIONS"
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- 2.  All MR-series SOPs **plus** the associated segmentation SOPs
union_sops AS (
    SELECT 
        "SOPInstanceUID",
        "Modality"
    FROM IDC.IDC_V17."DICOM_ALL"
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
       OR "SOPInstanceUID" IN (SELECT "SOPInstanceUID" FROM seg_sops)
)

-- 3.  Modality with the greatest number of SOPs in that union
SELECT 
    "Modality",
    COUNT(*) AS "total_sop_count"
FROM union_sops
GROUP BY "Modality"
ORDER BY "total_sop_count" DESC NULLS LAST
LIMIT 1;