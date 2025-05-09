SELECT DISTINCT Imaging_Assay_Type, 'Level1' AS Available_Data_Level
FROM `isb-cgc-bq.HTAN_versioned.imaging_level1_metadata_r5`
WHERE HTAN_Center = 'HTAN WUSTL'
  AND Component IS NOT NULL
  AND LOWER(Component) NOT LIKE '%auxiliary%'
  AND LOWER(Component) NOT LIKE '%otherassay%'

UNION ALL

SELECT DISTINCT Imaging_Assay_Type, 'Level2' AS Available_Data_Level
FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
WHERE HTAN_Center = 'HTAN WUSTL'
  AND Component IS NOT NULL
  AND LOWER(Component) NOT LIKE '%auxiliary%'
  AND LOWER(Component) NOT LIKE '%otherassay%'

UNION ALL

SELECT DISTINCT Component AS Imaging_Assay_Type, 'Level3' AS Available_Data_Level
FROM `isb-cgc-bq.HTAN_versioned.imaging_level3_segmentation_metadata_r5`
WHERE HTAN_Center = 'HTAN WUSTL'
  AND Component IS NOT NULL
  AND LOWER(Component) NOT LIKE '%auxiliary%'
  AND LOWER(Component) NOT LIKE '%otherassay%'

UNION ALL

SELECT DISTINCT Component AS Imaging_Assay_Type, 'Level4' AS Available_Data_Level
FROM `isb-cgc-bq.HTAN_versioned.imaging_level4_metadata_r5`
WHERE HTAN_Center = 'HTAN WUSTL'
  AND Component IS NOT NULL
  AND LOWER(Component) NOT LIKE '%auxiliary%'
  AND LOWER(Component) NOT LIKE '%otherassay%';