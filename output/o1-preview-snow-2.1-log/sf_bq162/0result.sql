SELECT DISTINCT "Assay_Type", "Data_Level"
FROM (
  SELECT 'Level2' AS "Data_Level", "Imaging_Assay_Type" AS "Assay_Type", "Component", "HTAN_Center"
  FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL2_METADATA_R5

  UNION ALL

  SELECT 'Level3' AS "Data_Level", "Imaging_Segmentation_Data_Type" AS "Assay_Type", "Component", "HTAN_Center"
  FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL3_SEGMENTATION_METADATA_R5

  UNION ALL

  SELECT 'Level4' AS "Data_Level", "Imaging_Object_Class" AS "Assay_Type", "Component", "HTAN_Center"
  FROM HTAN_1.HTAN_VERSIONED.IMAGING_LEVEL4_METADATA_R5
) AS CombinedData
WHERE "HTAN_Center" ILIKE '%WUSTL%'
  AND "Component" IS NOT NULL
  AND "Component" NOT ILIKE '%Auxiliary%'
  AND "Component" NOT ILIKE '%OtherAssay%';