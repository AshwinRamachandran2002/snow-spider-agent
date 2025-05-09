WITH mr AS (
    SELECT 
        COALESCE("Modality",'UNKNOWN')           AS modality,
        COUNT(DISTINCT "SOPInstanceUID")         AS total_sop_instances
    FROM IDC.IDC_V17.DICOM_METADATA
    WHERE "SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
    GROUP BY "Modality"
),
seg AS (
    SELECT 
        'SEG'                                    AS modality,
        COUNT(DISTINCT "SOPInstanceUID")         AS total_sop_instances
    FROM IDC.IDC_V17.SEGMENTATIONS
    WHERE "segmented_SeriesInstanceUID" = '1.3.6.1.4.1.14519.5.2.1.3671.4754.105976129314091491952445656147'
)
SELECT modality, total_sop_instances
FROM (
      SELECT * FROM mr
      UNION ALL
      SELECT * FROM seg
     )
ORDER BY total_sop_instances DESC NULLS LAST, modality
LIMIT 1;