SELECT
  Imaging_Assay_Type,
  Data_Level
FROM (
  SELECT
    'Level1' AS Data_Level,
    Imaging_Assay_Type
  FROM
    `isb-cgc-bq.HTAN_versioned.imaging_level1_metadata_r5`
  WHERE
    HTAN_Center = 'HTAN WUSTL'
    AND Component IS NOT NULL
    AND LOWER(Component) NOT LIKE '%auxiliary%'
    AND LOWER(Component) NOT LIKE '%otherassay%'

  UNION ALL

  SELECT
    'Level2' AS Data_Level,
    Imaging_Assay_Type
  FROM
    `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
  WHERE
    HTAN_Center = 'HTAN WUSTL'
    AND Component IS NOT NULL
    AND LOWER(Component) NOT LIKE '%auxiliary%'
    AND LOWER(Component) NOT LIKE '%otherassay%'

  UNION ALL

  SELECT
    'Level3' AS Data_Level,
    Imaging_Segmentation_Data_Type AS Imaging_Assay_Type
  FROM
    `isb-cgc-bq.HTAN_versioned.imaging_level3_segmentation_metadata_r5`
  WHERE
    HTAN_Center = 'HTAN WUSTL'
    AND Component IS NOT NULL
    AND LOWER(Component) NOT LIKE '%auxiliary%'
    AND LOWER(Component) NOT LIKE '%otherassay%'

  UNION ALL

  SELECT
    'Level4' AS Data_Level,
    Imaging_Object_Class AS Imaging_Assay_Type
  FROM
    `isb-cgc-bq.HTAN_versioned.imaging_level4_metadata_r5`
  WHERE
    HTAN_Center = 'HTAN WUSTL'
    AND Component IS NOT NULL
    AND LOWER(Component) NOT LIKE '%auxiliary%'
    AND LOWER(Component) NOT LIKE '%otherassay%'
)
GROUP BY
  Imaging_Assay_Type,
  Data_Level
ORDER BY
  Imaging_Assay_Type,
  Data_Level;