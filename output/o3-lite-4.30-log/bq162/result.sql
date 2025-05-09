WITH level2 AS (
  SELECT DISTINCT
         Imaging_Assay_Type,
         HTAN_Data_File_ID
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
  WHERE HTAN_Center = 'HTAN WUSTL'
    AND LOWER(Imaging_Assay_Type) NOT LIKE '%electron%'
    AND Component IS NOT NULL
    AND LOWER(Component) NOT LIKE '%auxiliary%'
    AND LOWER(Component) NOT LIKE '%otherassay%'
),
l2_with_children AS (
  SELECT
    l2.Imaging_Assay_Type,
    MAX(CASE WHEN p.Component = 'ImagingLevel3Segmentation' THEN 1 ELSE 0 END) AS has_level3,
    MAX(CASE WHEN p.Component = 'ImagingLevel4'             THEN 1 ELSE 0 END) AS has_level4
  FROM level2 AS l2
  LEFT JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS p
         ON p.HTAN_Parent_Data_File_ID = l2.HTAN_Data_File_ID
        AND p.Component IS NOT NULL
        AND LOWER(p.Component) NOT LIKE '%auxiliary%'
        AND LOWER(p.Component) NOT LIKE '%otherassay%'
  GROUP BY l2.Imaging_Assay_Type
)
SELECT
  Imaging_Assay_Type AS assay_type,
  CASE
    WHEN has_level3 = 1 AND has_level4 = 1 THEN 'Level2,Level3,Level4'
    WHEN has_level3 = 1 AND has_level4 = 0 THEN 'Level2,Level3'
    WHEN has_level3 = 0 AND has_level4 = 1 THEN 'Level2,Level4'
    ELSE 'Level2'
  END AS available_data_levels
FROM l2_with_children
ORDER BY assay_type;