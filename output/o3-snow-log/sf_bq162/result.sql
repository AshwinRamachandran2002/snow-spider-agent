/*  Imaging assay types at HTAN WUSTL with Level-2 data (r5) and any
    connected higher-level imaging data (Level-3 / Level-4) present in
    the ID_PROVENANCE_R5 table.  Level-1 data, Electron-Microscopy
    assays, NULL / “Auxiliary” / “OtherAssay” components are excluded.  */

WITH level2_wustl AS (      -- Level-2 imaging records for WUSTL
    SELECT DISTINCT
           "Imaging_Assay_Type" AS imaging_assay_type
    FROM   HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R2
    WHERE  "HTAN_Center" = 'HTAN WUSTL'
      AND  "Imaging_Assay_Type" IS NOT NULL
      AND  "Imaging_Assay_Type" NOT ILIKE '%electron%'        -- exclude EM
),

higher_levels AS (          -- Level-3 / Level-4 presence via ID-provenance
    SELECT DISTINCT 'Level3' AS level_tag
    FROM   HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE  "HTAN_CENTER" = 'HTAN WUSTL'
      AND  "COMPONENT" ILIKE 'ImagingLevel3%'
      AND  "COMPONENT" IS NOT NULL
      AND  "COMPONENT" NOT ILIKE '%Auxiliary%'
      AND  "COMPONENT" NOT ILIKE '%OtherAssay%'

    UNION
    SELECT DISTINCT 'Level4' AS level_tag
    FROM   HTAN_1.HTAN_VERSIONED.ID_PROVENANCE_R5
    WHERE  "HTAN_CENTER" = 'HTAN WUSTL'
      AND  "COMPONENT" ILIKE 'ImagingLevel4%'
      AND  "COMPONENT" IS NOT NULL
      AND  "COMPONENT" NOT ILIKE '%Auxiliary%'
      AND  "COMPONENT" NOT ILIKE '%OtherAssay%'
),

levels_per_assay AS (       -- combine Level-2 and any higher levels
    SELECT
        l2.imaging_assay_type,
        'Level2' AS level_label
    FROM level2_wustl l2

    UNION ALL
    SELECT
        l2.imaging_assay_type,
        hl.level_tag
    FROM level2_wustl l2
    JOIN higher_levels hl  ON 1 = 1          -- add higher levels if present
)

SELECT
    imaging_assay_type,
    LISTAGG(level_label, ', ') WITHIN GROUP (ORDER BY level_label) AS available_levels
FROM   levels_per_assay
GROUP  BY imaging_assay_type
ORDER  BY imaging_assay_type;