/*------------------------------------------------------------------
   Imaging assay types produced by the HTAN WUSTL centre that have
   Level-2 data in the R5 data set, together with any higher-level
   data (Level-3 / Level-4) detected through ID_PROVENANCE_R5.
   – Excludes Electron Microscopy and any Auxiliary / OtherAssay
     components.
-------------------------------------------------------------------*/

WITH level2_wustl AS (          /* ---- distinct Level-2 assay types ---- */
    SELECT DISTINCT "Imaging_Assay_Type" AS "Assay"
    FROM   "HTAN_1"."HTAN_VERSIONED"."IMAGING_LEVEL2_METADATA_R2"
    WHERE  "HTAN_Center" = 'HTAN WUSTL'
      AND  "Imaging_Assay_Type" NOT ILIKE 'Electron%'

    UNION
    SELECT DISTINCT "IMAGING_ASSAY_TYPE"  AS "Assay"
    FROM   "HTAN_1"."HTAN_VERSIONED"."IMAGING_LEVEL2_METADATA_R3"
    WHERE  "HTAN_CENTER" = 'HTAN WUSTL'
      AND  "IMAGING_ASSAY_TYPE" NOT ILIKE 'Electron%'

    UNION
    SELECT DISTINCT "IMAGING_ASSAY_TYPE"  AS "Assay"
    FROM   "HTAN_1"."HTAN_VERSIONED"."IMAGING_LEVEL2_METADATA_R4"
    WHERE  "HTAN_CENTER" = 'HTAN WUSTL'
      AND  "IMAGING_ASSAY_TYPE" NOT ILIKE 'Electron%'
),

level3_presence AS (            /* ---- at least one Level-3 object ? ---- */
    SELECT CASE
             WHEN COUNT(*) > 0 THEN 1 ELSE 0
           END AS "HAS_L3"
    FROM   "HTAN_1"."HTAN_VERSIONED"."ID_PROVENANCE_R5"
    WHERE  "HTAN_CENTER" = 'HTAN WUSTL'
      AND  "COMPONENT" ILIKE 'ImagingLevel3%'
      AND  "COMPONENT" NOT ILIKE '%Auxiliary%'
      AND  "COMPONENT" NOT ILIKE '%OtherAssay%'
),

level4_presence AS (            /* ---- at least one Level-4 object ? ---- */
    SELECT CASE
             WHEN COUNT(*) > 0 THEN 1 ELSE 0
           END AS "HAS_L4"
    FROM   "HTAN_1"."HTAN_VERSIONED"."ID_PROVENANCE_R5"
    WHERE  "HTAN_CENTER" = 'HTAN WUSTL'
      AND  "COMPONENT" ILIKE 'ImagingLevel4%'
      AND  "COMPONENT" NOT ILIKE '%Auxiliary%'
      AND  "COMPONENT" NOT ILIKE '%OtherAssay%'
),

levels_available AS (           /* ---- assemble assay-type / level pairs ---- */
    /* Level-2 exists by definition */
    SELECT "Assay" AS "Imaging_Assay_Type", 'Level2' AS "Level"
    FROM   level2_wustl

    UNION ALL
    /* add Level-3 to every assay type if any Level-3 data exist */
    SELECT w."Assay", 'Level3'
    FROM   level2_wustl w
           CROSS JOIN level3_presence p
    WHERE  p."HAS_L3" = 1

    UNION ALL
    /* add Level-4 to every assay type if any Level-4 data exist */
    SELECT w."Assay", 'Level4'
    FROM   level2_wustl w
           CROSS JOIN level4_presence p
    WHERE  p."HAS_L4" = 1
)

/* --------------------------- final report --------------------------- */
SELECT  "Imaging_Assay_Type",
        LISTAGG("Level", ', ') WITHIN GROUP (ORDER BY "Level")  AS "Available_Levels"
FROM    levels_available
GROUP BY "Imaging_Assay_Type"
ORDER BY "Imaging_Assay_Type";