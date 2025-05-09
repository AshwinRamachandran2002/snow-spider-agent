WITH
-- all SOP instances in the specified MR series
base_series AS (
    SELECT
        "SOPInstanceUID",
        "Modality"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- segmentation SOP instances that reference that MR series
seg_instances AS (
    /* via Quantitative Measurements */
    SELECT DISTINCT
        q."segmentationInstanceUID" AS "SOPInstanceUID"
    FROM IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS q
    WHERE q."sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    
    UNION
    
    /* via Segmentations table (if populated) */
    SELECT DISTINCT
        s."SOPInstanceUID"
    FROM IDC.IDC_V17.SEGMENTATIONS s
    WHERE s."segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- add modality information to the segmentation SOPs
seg_with_modality AS (
    SELECT
        d."Modality",
        d."SOPInstanceUID"
    FROM IDC.IDC_V17.DICOM_ALL d
    JOIN seg_instances si
      ON d."SOPInstanceUID" = si."SOPInstanceUID"
),

-- union of MR series SOPs and associated segmentation SOPs
all_sops AS (
    SELECT "Modality", "SOPInstanceUID" FROM base_series
    UNION ALL
    SELECT "Modality", "SOPInstanceUID" FROM seg_with_modality
)

-- count SOP instances per modality and pick the largest
SELECT
    "Modality",
    COUNT(DISTINCT "SOPInstanceUID") AS "Total_SOP_Instances"
FROM all_sops
GROUP BY "Modality"
ORDER BY "Total_SOP_Instances" DESC NULLS LAST
LIMIT 1;