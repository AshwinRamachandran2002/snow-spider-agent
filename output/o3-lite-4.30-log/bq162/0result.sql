WITH l2_filtered AS (
  SELECT
    l2.Imaging_Assay_Type,
    l2.HTAN_Data_File_ID
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5` AS l2
  JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS p2
    ON p2.entityId = l2.entityId
  WHERE l2.HTAN_Center = 'HTAN WUSTL'
    AND LOWER(l2.Imaging_Assay_Type) NOT LIKE '%electron microscopy%'
    AND p2.Component IS NOT NULL
    AND LOWER(p2.Component) NOT LIKE '%auxiliary%'
    AND LOWER(p2.Component) NOT LIKE '%otherassay%'
)
SELECT
  assay_type,
  STRING_AGG(level ORDER BY level) AS available_data_levels
FROM (
  SELECT DISTINCT
    Imaging_Assay_Type AS assay_type,
    'Level2'           AS level
  FROM l2_filtered
  
  UNION DISTINCT
  
  SELECT DISTINCT
    l2.Imaging_Assay_Type AS assay_type,
    'Level3'              AS level
  FROM l2_filtered AS l2
  WHERE EXISTS (
    SELECT 1
    FROM `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS p3
    WHERE p3.HTAN_Parent_Data_File_ID = l2.HTAN_Data_File_ID
      AND p3.Component = 'ImagingLevel3Segmentation'
      AND p3.Component IS NOT NULL
      AND LOWER(p3.Component) NOT LIKE '%auxiliary%'
      AND LOWER(p3.Component) NOT LIKE '%otherassay%'
  )
  
  UNION DISTINCT
  
  SELECT DISTINCT
    l2.Imaging_Assay_Type AS assay_type,
    'Level4'              AS level
  FROM l2_filtered AS l2
  WHERE EXISTS (
    SELECT 1
    FROM `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS p4
    WHERE p4.HTAN_Parent_Data_File_ID = l2.HTAN_Data_File_ID
      AND p4.Component = 'ImagingLevel4'
      AND p4.Component IS NOT NULL
      AND LOWER(p4.Component) NOT LIKE '%auxiliary%'
      AND LOWER(p4.Component) NOT LIKE '%otherassay%'
  )
)
GROUP BY assay_type
ORDER BY assay_type;