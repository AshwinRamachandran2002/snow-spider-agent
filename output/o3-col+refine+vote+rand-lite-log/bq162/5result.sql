--  Imaging assay types at HTAN-WUSTL that have Level-2 metadata and which
--  higher-level (Level-3 / Level-4) data also exist for the *same* entityId.
--  Excludes Electron-Microscopy assays and rows whose Component is NULL,
--  contains 'Auxiliary', or 'OtherAssay'.  Level-1 data are ignored.

WITH l2 AS (
  SELECT
      `entityId`,
      `Imaging_Assay_Type`
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
  WHERE `HTAN_Center` = 'HTAN WUSTL'
    AND LOWER(`Component`) = 'imaginglevel2'
    AND `Imaging_Assay_Type` IS NOT NULL
    AND LOWER(`Imaging_Assay_Type`) NOT LIKE '%electron%'          -- exclude EM
),

prov AS (
  SELECT
      `entityId`,
      LOWER(`Component`) AS comp_lower
  FROM `isb-cgc-bq.HTAN_versioned.id_provenance_r5`
  WHERE `Component` IS NOT NULL
    AND LOWER(`Component`) NOT LIKE '%auxiliary%'
    AND LOWER(`Component`) NOT LIKE '%otherassay%'
)

SELECT
    l2.Imaging_Assay_Type,
    TRUE  AS has_Level2,
    MAX( CASE WHEN prov.comp_lower LIKE 'imaginglevel3%' THEN TRUE ELSE FALSE END ) AS has_Level3,
    MAX( CASE WHEN prov.comp_lower LIKE 'imaginglevel4%' THEN TRUE ELSE FALSE END ) AS has_Level4
FROM l2
LEFT JOIN prov
  ON l2.entityId = prov.entityId
GROUP BY l2.Imaging_Assay_Type
ORDER BY l2.Imaging_Assay_Type;