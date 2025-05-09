WITH
-- Level‑2 imaging files produced at HTAN WUSTL
l2 AS (
  SELECT
    HTAN_Data_File_ID,
    Imaging_Assay_Type
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
  WHERE HTAN_Center = 'HTAN WUSTL'
    AND Component IS NOT NULL
    AND LOWER(Component) NOT LIKE '%auxiliary%'
    AND LOWER(Component) NOT LIKE '%otherassay%'
    AND Imaging_Assay_Type IS NOT NULL
    AND LOWER(Imaging_Assay_Type) NOT LIKE '%electron%'
),

-- Level‑3 files derived (via provenance) from the Level‑2 files above
l3_map AS (
  SELECT DISTINCT
    p.HTAN_Parent_Data_File_ID AS l2_id
  FROM `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS p
  WHERE p.HTAN_Parent_Data_File_ID IN (SELECT HTAN_Data_File_ID FROM l2)
    AND p.Component IS NOT NULL
    AND LOWER(p.Component) LIKE 'imaginglevel3%'
    AND LOWER(p.Component) NOT LIKE '%auxiliary%'
    AND LOWER(p.Component) NOT LIKE '%otherassay%'
),

-- Level‑4 files whose parent is a Level‑2 file
l4_parent_is_l2 AS (
  SELECT DISTINCT
    p.HTAN_Parent_Data_File_ID AS l2_id
  FROM `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS p
  WHERE p.HTAN_Parent_Data_File_ID IN (SELECT HTAN_Data_File_ID FROM l2)
    AND p.Component IS NOT NULL
    AND LOWER(p.Component) LIKE 'imaginglevel4%'
    AND LOWER(p.Component) NOT LIKE '%auxiliary%'
    AND LOWER(p.Component) NOT LIKE '%otherassay%'
),

-- Level‑4 files whose parent is a Level‑3 file that descends from a Level‑2 file
l4_parent_is_l3 AS (
  SELECT DISTINCT
    l3.HTAN_Parent_Data_File_ID AS l2_id
  FROM `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS l4
  JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS l3
    ON l4.HTAN_Parent_Data_File_ID = l3.HTAN_Data_File_ID
  WHERE l4.Component IS NOT NULL
    AND LOWER(l4.Component) LIKE 'imaginglevel4%'
    AND LOWER(l4.Component) NOT LIKE '%auxiliary%'
    AND LOWER(l4.Component) NOT LIKE '%otherassay%'
    AND l3.Component IS NOT NULL
    AND LOWER(l3.Component) LIKE 'imaginglevel3%'
    AND LOWER(l3.Component) NOT LIKE '%auxiliary%'
    AND LOWER(l3.Component) NOT LIKE '%otherassay%'
    AND l3.HTAN_Parent_Data_File_ID IN (SELECT HTAN_Data_File_ID FROM l2)
),

-- All Level‑4 mappings combined
l4_map AS (
  SELECT * FROM l4_parent_is_l2
  UNION DISTINCT
  SELECT * FROM l4_parent_is_l3
),

-- Union of levels available for each Level‑2 HTAN ID
levels_union AS (
  SELECT HTAN_Data_File_ID AS l2_id, 'Level2' AS level FROM l2
  UNION DISTINCT
  SELECT l2_id, 'Level3' FROM l3_map
  UNION DISTINCT
  SELECT l2_id, 'Level4' FROM l4_map
)

-- Final aggregation: imaging assay type and its available data levels
SELECT
  l2.Imaging_Assay_Type AS assay_type,
  STRING_AGG(DISTINCT level ORDER BY level) AS available_data_levels
FROM l2
JOIN levels_union
  ON l2.HTAN_Data_File_ID = levels_union.l2_id
GROUP BY assay_type
ORDER BY assay_type;