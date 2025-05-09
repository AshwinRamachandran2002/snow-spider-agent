WITH imaging_sops AS (
    SELECT DISTINCT 'MR' AS modality,
                    "SOPInstanceUID"
    FROM   "IDC"."IDC_V17"."DICOM_METADATA"
    WHERE  "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
seg_sops AS (
    SELECT DISTINCT 'SEG' AS modality,
                    "SOPInstanceUID"
    FROM   "IDC"."IDC_V17"."SEGMENTATIONS"
    WHERE  "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
),
all_sops AS (
    SELECT * FROM imaging_sops
    UNION ALL
    SELECT * FROM seg_sops
)
SELECT   modality,
         COUNT(DISTINCT "SOPInstanceUID") AS total_sop_instances
FROM     all_sops
GROUP BY modality
ORDER BY total_sop_instances DESC NULLS LAST,
         modality
LIMIT 1;