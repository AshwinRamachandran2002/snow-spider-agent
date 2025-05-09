-- Imaging assay types at HTAN WUSTL with Level-2 files and
-- any higher-level (Level-3 / Level-4) metadata linked through id_provenance_r5
WITH level2 AS (
  SELECT DISTINCT
         Imaging_Assay_Type,
         entityId
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
  WHERE HTAN_Center = 'HTAN WUSTL'                       -- WUSTL center only
    AND Imaging_Assay_Type IS NOT NULL                  -- keep defined assay types
    AND LOWER(Imaging_Assay_Type) NOT LIKE '%electron%' -- drop Electron Microscopy
),
levels_union AS (
  -- Always include the presence of Level-2
  SELECT
    Imaging_Assay_Type,
    'Level2' AS level
  FROM level2
  
  UNION ALL
  
  -- Add Level-3 / Level-4 indicated by provenance components
  SELECT
    l2.Imaging_Assay_Type,
    CASE
      WHEN LOWER(p.Component) LIKE '%level3%' THEN 'Level3'
      WHEN LOWER(p.Component) LIKE '%level4%' THEN 'Level4'
    END AS level
  FROM level2 AS l2
  JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS p
    ON l2.entityId = p.entityId
  WHERE p.Component IS NOT NULL
    AND LOWER(p.Component) NOT LIKE '%auxiliary%'       -- exclude unwanted components
    AND LOWER(p.Component) NOT LIKE '%otherassay%'
    AND (LOWER(p.Component) LIKE '%level3%' 
         OR LOWER(p.Component) LIKE '%level4%')         -- keep higher-level only
)
SELECT
  Imaging_Assay_Type,
  STRING_AGG(DISTINCT level ORDER BY level) AS available_levels
FROM levels_union
GROUP BY Imaging_Assay_Type
ORDER BY Imaging_Assay_Type;