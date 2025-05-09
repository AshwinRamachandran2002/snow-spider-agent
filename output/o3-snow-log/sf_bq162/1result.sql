/*  List imaging assay types that have Level-2 data at the HTAN WUSTL
    centre (5th release), together with any higher-level data
    (Level-3 / Level-4) that are linked through the ID_PROVENANCE_R5
    table.  Auxiliary or OtherAssay components are excluded.           */

WITH level2_wustl AS (          -- all Level-2 imaging assay types
    SELECT DISTINCT
           "Imaging_Assay_Type"      AS imaging_assay_type
    FROM   HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R2
    WHERE  "HTAN_Center" = 'HTAN WUSTL'
      AND  "Component"      IS NOT NULL
      AND  "Component"     NOT ILIKE '%Auxiliary%'
      AND  "Component"     NOT ILIKE '%OtherAssay%'
      AND  "Imaging_Assay_Type" IS NOT NULL
),                                -- presence of Level-3 data
lvl3_present AS (
    SELECT COUNT(*) > 0 AS has_lvl3
    FROM   HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE  "HTAN_CENTER" = 'HTAN WUSTL'
      AND  "COMPONENT" ILIKE '%Level3%'
      AND  "COMPONENT" NOT ILIKE '%Auxiliary%'
      AND  "COMPONENT" NOT ILIKE '%OtherAssay%'
),                                -- presence of Level-4 data
lvl4_present AS (
    SELECT COUNT(*) > 0 AS has_lvl4
    FROM   HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE  "HTAN_CENTER" = 'HTAN WUSTL'
      AND  "COMPONENT" ILIKE '%Level4%'
      AND  "COMPONENT" NOT ILIKE '%Auxiliary%'
      AND  "COMPONENT" NOT ILIKE '%OtherAssay%'
),                                -- assemble levels for each assay
assay_levels AS (
    SELECT imaging_assay_type,
           'Level2' AS data_level
    FROM   level2_wustl

    UNION ALL
    SELECT imaging_assay_type,
           'Level3'
    FROM   level2_wustl, lvl3_present
    WHERE  has_lvl3

    UNION ALL
    SELECT imaging_assay_type,
           'Level4'
    FROM   level2_wustl, lvl4_present
    WHERE  has_lvl4
)

SELECT imaging_assay_type                     AS "Imaging_Assay_Type",
       LISTAGG(DISTINCT data_level, ', ')
         WITHIN GROUP (ORDER BY data_level)   AS "Available_Data_Levels"
FROM   assay_levels
GROUP  BY imaging_assay_type
ORDER  BY imaging_assay_type;