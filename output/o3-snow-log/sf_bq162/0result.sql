/*  Imaging assay types with Level-2 data at HTAN WUSTL and any higher-level
    (Level-3 / Level-4) data linked through ID_PROVENANCE_R5                */
WITH wustl_lvl2 AS (          -- Level-2 imaging assay types at WUSTL
    SELECT DISTINCT
           "Imaging_Assay_Type" AS imaging_assay_type
    FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R2
    WHERE "HTAN_Center" = 'HTAN WUSTL'
      AND "Component"   = 'ImagingLevel2'
      AND "Imaging_Assay_Type" NOT ILIKE '%electron%'           -- exclude EM
),
lvl3_present AS (             -- does any Imaging-Level-3 exist for WUSTL?
    SELECT 1
    FROM HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
      AND "COMPONENT" IS NOT NULL
      AND "COMPONENT" NOT ILIKE '%Auxiliary%'
      AND "COMPONENT" NOT ILIKE '%OtherAssay%'
      AND LOWER("COMPONENT") LIKE 'imaging%level3%'
    LIMIT 1
),
lvl4_present AS (             -- does any Imaging-Level-4 exist for WUSTL?
    SELECT 1
    FROM HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
      AND "COMPONENT" IS NOT NULL
      AND "COMPONENT" NOT ILIKE '%Auxiliary%'
      AND "COMPONENT" NOT ILIKE '%OtherAssay%'
      AND LOWER("COMPONENT") LIKE 'imaging%level4%'
    LIMIT 1
),
levels_union AS (             -- build (assay_type , level) pairs
    /* Level-2 is always present */
    SELECT imaging_assay_type, 'Level2' AS level
    FROM   wustl_lvl2
    UNION ALL
    /* add Level-3 if any exists */
    SELECT imaging_assay_type, 'Level3' AS level
    FROM   wustl_lvl2
    WHERE  EXISTS (SELECT * FROM lvl3_present)
    UNION ALL
    /* add Level-4 if any exists */
    SELECT imaging_assay_type, 'Level4' AS level
    FROM   wustl_lvl2
    WHERE  EXISTS (SELECT * FROM lvl4_present)
)
SELECT
    imaging_assay_type                                   AS "IMAGING_ASSAY_TYPE",
    LISTAGG(level, ', ') WITHIN GROUP (ORDER BY level)   AS "AVAILABLE_LEVELS"
FROM levels_union
GROUP BY 1
ORDER BY 1;