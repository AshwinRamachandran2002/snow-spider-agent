-- Imaging assay types at HTAN WUSTL with Level 2 data and any
-- associated Level 3/4 data derived from them
WITH lvl2 AS (           -- all WUSTL imaging-Level2 files
  SELECT DISTINCT
         HTAN_Data_File_ID,
         Imaging_Assay_Type
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
  WHERE HTAN_Center = 'HTAN WUSTL'
    AND Component IS NOT NULL
    AND LOWER(Component) NOT LIKE '%auxiliary%'
    AND LOWER(Component) NOT LIKE '%otherassay%'
    AND LOWER(Imaging_Assay_Type) NOT LIKE '%electron%'       -- exclude EM
),
higher AS (              -- Level3/4 children that cite those Level2 files
  SELECT
    l2.Imaging_Assay_Type,
    CASE
      WHEN LOWER(p.Component) LIKE '%level3%' THEN 'Level3'
      WHEN LOWER(p.Component) LIKE '%level4%' THEN 'Level4'
    END AS level_label
  FROM `isb-cgc-bq.HTAN_versioned.id_provenance_r5` p
  JOIN lvl2 l2
    ON p.HTAN_Parent_Data_File_ID = l2.HTAN_Data_File_ID
  WHERE p.HTAN_Center = 'HTAN WUSTL'
    AND p.Component IS NOT NULL
    AND (LOWER(p.Component) LIKE '%level3%' OR LOWER(p.Component) LIKE '%level4%')
    AND LOWER(p.Component) NOT LIKE '%auxiliary%'
    AND LOWER(p.Component) NOT LIKE '%otherassay%'
)
SELECT
  Imaging_Assay_Type,
  STRING_AGG(DISTINCT level_label ORDER BY level_label) AS available_levels
FROM (
  SELECT Imaging_Assay_Type, 'Level2' AS level_label FROM lvl2
  UNION ALL
  SELECT * FROM higher
)
GROUP BY Imaging_Assay_Type
ORDER BY Imaging_Assay_Type;