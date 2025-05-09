/*  Imaging assay types with Level-2 data at HTAN WUSTL (revision 5) and the
    highest downstream data levels (Level-3/Level-4) present for the same
    centre, ignoring Auxiliary / OtherAssay components and Electron Microscopy. */

WITH level2_wustl AS (          -- all assay types that have Level-2 data
    SELECT DISTINCT imaging_assay_type
    FROM (
        /* R2 table (mixed-case column names) */
        SELECT "Imaging_Assay_Type" AS imaging_assay_type
        FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R2
        WHERE "HTAN_Center" = 'HTAN WUSTL'
          AND "Component"   = 'ImagingLevel2'
        
        UNION ALL
        
        /* R3 table (upper-case column names) */
        SELECT "IMAGING_ASSAY_TYPE" AS imaging_assay_type
        FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R3
        WHERE "HTAN_CENTER" = 'HTAN WUSTL'
          AND "COMPONENT"   = 'ImagingLevel2'
        
        UNION ALL
        
        /* R4 table (upper-case column names) */
        SELECT "IMAGING_ASSAY_TYPE" AS imaging_assay_type
        FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R4
        WHERE "HTAN_CENTER" = 'HTAN WUSTL'
          AND "COMPONENT"   = 'ImagingLevel2'
    )
    WHERE imaging_assay_type IS NOT NULL
      AND UPPER(imaging_assay_type) NOT LIKE '%ELECTRON%'   -- exclude EM
),
higher_levels AS (            -- detect presence of Level-3/Level-4 components
    SELECT
        MAX(CASE WHEN UPPER("COMPONENT") LIKE 'IMAGINGLEVEL3%' THEN 1 ELSE 0 END) AS has_l3,
        MAX(CASE WHEN UPPER("COMPONENT") LIKE 'IMAGINGLEVEL4%' THEN 1 ELSE 0 END) AS has_l4
    FROM HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
      AND "COMPONENT" IS NOT NULL
      AND UPPER("COMPONENT") NOT LIKE '%AUXILIARY%'
      AND UPPER("COMPONENT") NOT LIKE '%OTHERASSAY%'
)

SELECT
    l.imaging_assay_type                               AS "Imaging_Assay_Type",
    LISTAGG(level_tag, ', ') WITHIN GROUP (ORDER BY level_tag)
                                                      AS "Available_Data_Levels"
FROM level2_wustl l
CROSS JOIN (          -- always Level-2; add 3/4 if present
        SELECT 'Level2' AS level_tag
        UNION ALL SELECT 'Level3' FROM higher_levels WHERE has_l3 = 1
        UNION ALL SELECT 'Level4' FROM higher_levels WHERE has_l4 = 1
) tags
GROUP BY l.imaging_assay_type
ORDER BY l.imaging_assay_type;