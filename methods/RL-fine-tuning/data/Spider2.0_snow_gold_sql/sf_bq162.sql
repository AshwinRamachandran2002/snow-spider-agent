SELECT DISTINCT "Imaging_Assay_Type", 'Level1' AS "Data_Level"
FROM "HTAN_1"."HTAN_VERSIONED"."IMAGING_LEVEL1_METADATA_R5"
WHERE "Component" IS NOT NULL
  AND "Component" NOT ILIKE '%Auxiliary%'
  AND "Component" NOT ILIKE '%OtherAssay%'
  AND "HTAN_Center" = 'HTAN WUSTL'

UNION ALL

SELECT DISTINCT "Imaging_Assay_Type", 'Level2' AS "Data_Level"
FROM "HTAN_1"."HTAN_VERSIONED"."IMAGING_LEVEL2_METADATA_R5"
WHERE "Component" IS NOT NULL
  AND "Component" NOT ILIKE '%Auxiliary%'
  AND "Component" NOT ILIKE '%OtherAssay%'
  AND "HTAN_Center" = 'HTAN WUSTL'

UNION ALL

SELECT DISTINCT "Imaging_Segmentation_Data_Type" AS "Imaging_Assay_Type", 'Level3' AS "Data_Level"
FROM "HTAN_1"."HTAN_VERSIONED"."IMAGING_LEVEL3_SEGMENTATION_METADATA_R5"
WHERE "Component" IS NOT NULL
  AND "Component" NOT ILIKE '%Auxiliary%'
  AND "Component" NOT ILIKE '%OtherAssay%'
  AND "HTAN_Center" = 'HTAN WUSTL'

UNION ALL

SELECT DISTINCT "Imaging_Object_Class" AS "Imaging_Assay_Type", 'Level4' AS "Data_Level"
FROM "HTAN_1"."HTAN_VERSIONED"."IMAGING_LEVEL4_METADATA_R5"
WHERE "Component" IS NOT NULL
  AND "Component" NOT ILIKE '%Auxiliary%'
  AND "Component" NOT ILIKE '%OtherAssay%'
  AND "HTAN_Center" = 'HTAN WUSTL'

ORDER BY "Imaging_Assay_Type", "Data_Level";