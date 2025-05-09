/* -----------------------------------------------------------
   Imaging assay types present at HTAN WUSTL that have Level-2
   data and any higher-level (Level-3 / Level-4) data that can
   be linked to those Level-2 files through entityId entries in
   `id_provenance_r5`.  Excludes components that are NULL or
   contain ‘Auxiliary’ or ‘OtherAssay’, and omits Electron-
   Microscopy assay types.
---------------------------------------------------------------- */
WITH level2_files AS (         -- all WUSTL Level-2 imaging files
  SELECT
    l2.Imaging_Assay_Type,
    l2.HTAN_Data_File_ID,
    l2.entityId
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`  AS l2
  WHERE l2.HTAN_Center               = 'HTAN WUSTL'
    AND l2.Imaging_Assay_Type        IS NOT NULL
    AND LOWER(l2.Imaging_Assay_Type) NOT LIKE '%electron%'
),

/* ---------- Level-2 presence (always true for rows above) ---- */
level2_presence AS (
  SELECT DISTINCT
    Imaging_Assay_Type,
    'Level2' AS lvl
  FROM level2_files
),

/* ---------- Level-3 presence via id_provenance --------------- */
level3_presence AS (
  SELECT DISTINCT
    l2.Imaging_Assay_Type,
    'Level3' AS lvl
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level3_segmentation_metadata_r3` AS l3
  JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5`                           AS p
       ON  p.entityId   = l3.entityId
      AND p.HTAN_Center = 'HTAN WUSTL'
      AND p.Component  IS NOT NULL
      AND p.Component NOT LIKE '%Auxiliary%'
      AND p.Component NOT LIKE '%OtherAssay%'
  JOIN level2_files AS l2                       -- map back to assay type
       ON l3.HTAN_Parent_Data_File_ID = l2.HTAN_Data_File_ID
),

/* ---------- Level-4 presence via id_provenance --------------- */
level4_presence AS (
  SELECT DISTINCT
    l2.Imaging_Assay_Type,
    'Level4' AS lvl
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level4_metadata_r5` AS l4
  JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5`            AS p
       ON  p.entityId   = l4.entityId
      AND p.HTAN_Center = 'HTAN WUSTL'
      AND p.Component  IS NOT NULL
      AND p.Component NOT LIKE '%Auxiliary%'
      AND p.Component NOT LIKE '%OtherAssay%'
  JOIN level2_files AS l2                       -- map back to assay type
       ON l4.HTAN_Parent_Data_File_ID = l2.HTAN_Data_File_ID
),

/* ---------- union all detected levels ------------------------ */
all_levels AS (
  SELECT * FROM level2_presence
  UNION DISTINCT
  SELECT * FROM level3_presence
  UNION DISTINCT
  SELECT * FROM level4_presence
)

/* ---------- final summary ------------------------------------ */
SELECT
  Imaging_Assay_Type,
  STRING_AGG(lvl ORDER BY lvl) AS available_levels
FROM all_levels
GROUP BY Imaging_Assay_Type
ORDER BY Imaging_Assay_Type;