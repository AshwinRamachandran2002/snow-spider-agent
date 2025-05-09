/* Which modality has the most SOP instances in the MR series
   1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147
   when combined with all of its associated segmentation objects? */

WITH
/* SOPs in the original MR series */
mr AS (
    SELECT "SOPInstanceUID"
    FROM   IDC.IDC_V17.DICOM_ALL
    WHERE  "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

/* Segmentation SOPs linked via quantitative measurements */
seg_qm AS (
    SELECT  DISTINCT "segmentationInstanceUID" AS "SOPInstanceUID"
    FROM    IDC.IDC_V17.QUANTITATIVE_MEASUREMENTS
    WHERE   "sourceSegmentedSeriesUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

/* Segmentation SOPs linked via the SEGMENTATIONS table */
seg_seg AS (
    SELECT  DISTINCT "SOPInstanceUID"
    FROM    IDC.IDC_V17.SEGMENTATIONS
    WHERE   "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),

/* Union of all relevant SOPInstanceUIDs */
all_uids AS (
    SELECT * FROM mr
    UNION ALL
    SELECT * FROM seg_qm
    UNION ALL
    SELECT * FROM seg_seg
)

/* Count SOP instances by modality */
SELECT
    d."Modality",
    COUNT(*) AS sop_instance_count
FROM        IDC.IDC_V17.DICOM_ALL d
INNER JOIN  all_uids u
        ON  d."SOPInstanceUID" = u."SOPInstanceUID"
GROUP BY    d."Modality"
ORDER BY    sop_instance_count DESC NULLS LAST
LIMIT 1;