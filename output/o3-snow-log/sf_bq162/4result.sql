/*  Imaging assay types at HTAN WUSTL that have Level-2 data
    (any table included in the R5 bundle) and any associated
    higher-level (Level-3/Level-4) imaging data recorded through
    ID_PROVENANCE_R5.                                          */

WITH lvl2 AS (                 -- WUSTL Level-2 imaging assay types
    SELECT DISTINCT "Imaging_Assay_Type" AS "assay_type"
    FROM  HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R2
    WHERE "HTAN_Center" = 'HTAN WUSTL'

    UNION

    SELECT DISTINCT "IMAGING_ASSAY_TYPE"
    FROM  HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R3
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'

    UNION

    SELECT DISTINCT "IMAGING_ASSAY_TYPE"
    FROM  HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R4
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
),

higher AS (                    -- Level-3 / Level-4 data for WUSTL
    SELECT DISTINCT
           CASE
               WHEN UPPER("COMPONENT") LIKE 'IMAGINGLEVEL3%' THEN 'Level3'
               WHEN UPPER("COMPONENT") LIKE 'IMAGINGLEVEL4%' THEN 'Level4'
           END AS "level"
    FROM  HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE "HTAN_CENTER" = 'HTAN WUSTL'
      AND "COMPONENT" IS NOT NULL
      AND UPPER("COMPONENT") NOT ILIKE '%AUXILIARY%'
      AND UPPER("COMPONENT") NOT ILIKE '%OTHERASSAY%'
      AND (UPPER("COMPONENT") LIKE 'IMAGINGLEVEL3%'
           OR UPPER("COMPONENT") LIKE 'IMAGINGLEVEL4%')
),

combined AS (                  -- Combine Level-2 with any higher levels
    SELECT  l."assay_type", 'Level2' AS "level"
    FROM    lvl2 l
    UNION ALL
    SELECT  l."assay_type", h."level"
    FROM    lvl2 l
    JOIN    higher h  ON 1 = 1          -- same centre; add higher levels
)

SELECT
       "assay_type"                                               AS "Imaging_Assay_Type",
       LISTAGG(DISTINCT "level", ', ')
         WITHIN GROUP (ORDER BY "level")                          AS "Available_Data_Levels"
FROM   combined
GROUP  BY "assay_type"
ORDER  BY "Imaging_Assay_Type";