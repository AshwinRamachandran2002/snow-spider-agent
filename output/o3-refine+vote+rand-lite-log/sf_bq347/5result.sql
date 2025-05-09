WITH
-- SOPs in the requested MR series
mr_sops AS (
    SELECT DISTINCT
           "SOPInstanceUID",
           "Modality"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- Segmentation SOPs that reference the requested MR series
seg_sops AS (
    SELECT DISTINCT
           mg."segmentationInstanceUID"  AS "SOPInstanceUID"
    FROM   IDC.IDC_V17.MEASUREMENT_GROUPS mg
    WHERE  mg."sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

-- Attach modality to the segmentation SOPs
seg_sops_mod AS (
    SELECT
           da."SOPInstanceUID",
           da."Modality"
    FROM   seg_sops s
           JOIN IDC.IDC_V17.DICOM_ALL da
             ON da."SOPInstanceUID" = s."SOPInstanceUID"
),

-- Union MR and segmentation SOPs, then count by modality
all_sops AS (
    SELECT * FROM mr_sops
    UNION ALL
    SELECT * FROM seg_sops_mod
)

SELECT
       "Modality",
       COUNT(*) AS "SOP_Count"
FROM   all_sops
GROUP  BY "Modality"
ORDER  BY "SOP_Count" DESC
LIMIT 1;