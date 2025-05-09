/*  Imaging assay types with Level-2 data for HTAN WUSTL and the
    availability of higher-level (Level-3 / Level-4) imaging data
    based on the ID_PROVENANCE_R5 table                                      */

WITH level2_wustl AS (        -- collect every Level-2 imaging assay type for WUSTL
    ----------------------------------------------------------------------
    SELECT DISTINCT
           "Imaging_Assay_Type"          AS "Imaging_Assay_Type"
    FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R2
    WHERE "HTAN_Center" = 'HTAN WUSTL'
      AND "Component" IS NOT NULL
      AND UPPER("Component") NOT LIKE '%AUXILIARY%'
      AND UPPER("Component") NOT LIKE '%OTHERASSAY%'
      AND UPPER("Imaging_Assay_Type") NOT LIKE '%ELECTRON%'

    UNION

    SELECT DISTINCT
           "IMAGING_ASSAY_TYPE"          AS "Imaging_Assay_Type"
    FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R3
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
      AND "COMPONENT" IS NOT NULL
      AND UPPER("COMPONENT") NOT LIKE '%AUXILIARY%'
      AND UPPER("COMPONENT") NOT LIKE '%OTHERASSAY%'
      AND UPPER("IMAGING_ASSAY_TYPE") NOT LIKE '%ELECTRON%'

    UNION

    SELECT DISTINCT
           "IMAGING_ASSAY_TYPE"          AS "Imaging_Assay_Type"
    FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R4
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
      AND "COMPONENT" IS NOT NULL
      AND UPPER("COMPONENT") NOT LIKE '%AUXILIARY%'
      AND UPPER("COMPONENT") NOT LIKE '%OTHERASSAY%'
      AND UPPER("IMAGING_ASSAY_TYPE") NOT LIKE '%ELECTRON%'
),

level3_flag AS (              -- any Level-3 imaging data for WUSTL?
    SELECT 1 AS has_level3
    FROM HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
      AND "COMPONENT" IS NOT NULL
      AND UPPER("COMPONENT") LIKE 'IMAGING%LEVEL3%'
      AND UPPER("COMPONENT") NOT LIKE '%AUXILIARY%'
      AND UPPER("COMPONENT") NOT LIKE '%OTHERASSAY%'
    LIMIT 1
),

level4_flag AS (              -- any Level-4 imaging data for WUSTL?
    SELECT 1 AS has_level4
    FROM HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
      AND "COMPONENT" IS NOT NULL
      AND UPPER("COMPONENT") LIKE 'IMAGING%LEVEL4%'
      AND UPPER("COMPONENT") NOT LIKE '%AUXILIARY%'
      AND UPPER("COMPONENT") NOT LIKE '%OTHERASSAY%'
    LIMIT 1
),

levels_union AS (             -- create one row per assay type per level present
    SELECT l2."Imaging_Assay_Type", 'Level2' AS level
    FROM   level2_wustl l2

    UNION ALL
    SELECT l2."Imaging_Assay_Type", 'Level3'
    FROM   level2_wustl l2
    JOIN   level3_flag ON 1=1          -- include Level-3 if at least one exists

    UNION ALL
    SELECT l2."Imaging_Assay_Type", 'Level4'
    FROM   level2_wustl l2
    JOIN   level4_flag ON 1=1          -- include Level-4 if at least one exists
)

SELECT
    "Imaging_Assay_Type",
    LISTAGG(level, ', ') WITHIN GROUP (ORDER BY level) AS "Available_Data_Levels"
FROM levels_union
GROUP BY "Imaging_Assay_Type"
ORDER BY "Imaging_Assay_Type";