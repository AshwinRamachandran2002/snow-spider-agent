/*  Imaging assay types with Level2 data at HTAN WUSTL (r5) and any
    related higher-level imaging data present in ID_PROVENANCE_R5      */

WITH level2_wustl AS (   -- Level-2 imaging metadata coming from WUSTL
    SELECT DISTINCT "Imaging_Assay_Type" AS imaging_assay_type
    FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R2
    WHERE "HTAN_Center" = 'HTAN WUSTL'

    UNION ALL
    SELECT DISTINCT "IMAGING_ASSAY_TYPE"
    FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R3
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'

    UNION ALL
    SELECT DISTINCT "IMAGING_ASSAY_TYPE"
    FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R4
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
),

level_components AS (   -- Higher-level imaging data registered for WUSTL
    SELECT DISTINCT
           CASE
               WHEN UPPER("COMPONENT") LIKE 'IMAGINGLEVEL3%' THEN 'Level3'
               WHEN UPPER("COMPONENT") LIKE 'IMAGINGLEVEL4%' THEN 'Level4'
           END AS level
    FROM HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
      AND "COMPONENT" IS NOT NULL
      AND "COMPONENT" NOT ILIKE '%Auxiliary%'
      AND "COMPONENT" NOT ILIKE '%OtherAssay%'
      AND (   UPPER("COMPONENT") LIKE 'IMAGINGLEVEL3%'
           OR UPPER("COMPONENT") LIKE 'IMAGINGLEVEL4%' )
),

levels_union AS (       -- Combine Level2 with any higher levels found
    SELECT
        l2.imaging_assay_type,
        'Level2' AS level
    FROM level2_wustl l2

    UNION ALL
    SELECT
        l2.imaging_assay_type,
        lc.level
    FROM level2_wustl l2
    JOIN level_components lc
          ON lc.level IS NOT NULL
)

SELECT
    imaging_assay_type           AS "Imaging_Assay_Type",
    LISTAGG(level, ', ') 
        WITHIN GROUP (ORDER BY level) AS "Available_Levels"
FROM levels_union
GROUP BY imaging_assay_type
ORDER BY imaging_assay_type;