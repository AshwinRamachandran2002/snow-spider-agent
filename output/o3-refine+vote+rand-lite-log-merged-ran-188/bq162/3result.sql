-- Imaging assay types at HTAN WUSTL that have Level-2 data and
-- any higher–level data (Level-3/Level-4) connected through the
-- same `entityId` in the provenance table.
WITH l2_filtered AS (
  SELECT
    entityId,
    Imaging_Assay_Type
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
  WHERE HTAN_Center = 'HTAN WUSTL'
    AND Imaging_Assay_Type IS NOT NULL
    AND LOWER(Imaging_Assay_Type) NOT LIKE '%electron%'      -- exclude EM
),
prov_filtered AS (
  SELECT
    entityId,
    Component
  FROM `isb-cgc-bq.HTAN_versioned.id_provenance_r5`
  WHERE Component IS NOT NULL
    AND LOWER(Component) NOT LIKE '%auxiliary%'              -- drop Auxiliary
    AND LOWER(Component) NOT LIKE '%otherassay%'             -- drop OtherAssay
)
SELECT
  l2.Imaging_Assay_Type,
  'Level2'                                                     AS Level2_available,
  CASE WHEN SUM(CASE WHEN prov.Component LIKE '%Level3%' THEN 1 ELSE 0 END) > 0
       THEN 'Level3' END                                       AS Level3_available,
  CASE WHEN SUM(CASE WHEN prov.Component LIKE '%Level4%' THEN 1 ELSE 0 END) > 0
       THEN 'Level4' END                                       AS Level4_available
FROM l2_filtered AS l2
LEFT JOIN prov_filtered AS prov
  ON l2.entityId = prov.entityId
GROUP BY l2.Imaging_Assay_Type
ORDER BY l2.Imaging_Assay_Type;