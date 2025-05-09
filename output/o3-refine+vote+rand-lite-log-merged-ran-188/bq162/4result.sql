-- Imaging assay types at HTAN-WUSTL that have Level-2 data and any
-- higher-level (Level-3 / Level-4) data derived from the same entityId.
WITH wustl_l2 AS (
  SELECT
    `entityId`,
    `Imaging_Assay_Type`
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
  WHERE LOWER(`HTAN_Center`)   = 'htan wustl'        -- WUSTL only
    AND LOWER(`Component`)     = 'imaginglevel2'     -- Level-2 imaging rows
    AND `Imaging_Assay_Type`  IS NOT NULL
    AND LOWER(`Imaging_Assay_Type`) NOT LIKE '%electron%'   -- exclude EM
),

level_flags AS (
  -- Level-2 (present by definition)
  SELECT DISTINCT
         `Imaging_Assay_Type`,
         'Level2' AS level_label,
         2        AS level_order
  FROM wustl_l2

  UNION ALL

  -- Level-3 derived from the same entityId
  SELECT DISTINCT
         l2.`Imaging_Assay_Type`,
         'Level3' AS level_label,
         3        AS level_order
  FROM wustl_l2 AS l2
  JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS idp
    ON l2.`entityId` = idp.`entityId`
  WHERE idp.`Component` IS NOT NULL
    AND LOWER(idp.`Component`) LIKE  'imaginglevel3%'
    AND LOWER(idp.`Component`) NOT LIKE '%auxiliary%'
    AND LOWER(idp.`Component`) NOT LIKE '%otherassay%'

  UNION ALL

  -- Level-4 derived from the same entityId
  SELECT DISTINCT
         l2.`Imaging_Assay_Type`,
         'Level4' AS level_label,
         4        AS level_order
  FROM wustl_l2 AS l2
  JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS idp
    ON l2.`entityId` = idp.`entityId`
  WHERE idp.`Component` IS NOT NULL
    AND LOWER(idp.`Component`) LIKE  'imaginglevel4%'
    AND LOWER(idp.`Component`) NOT LIKE '%auxiliary%'
    AND LOWER(idp.`Component`) NOT LIKE '%otherassay%'
)

SELECT
  `Imaging_Assay_Type`,
  STRING_AGG(level_label, ',' ORDER BY level_order) AS available_levels
FROM (
  SELECT DISTINCT * FROM level_flags      -- ensure one row per level label
)
GROUP BY `Imaging_Assay_Type`
ORDER BY `Imaging_Assay_Type`;