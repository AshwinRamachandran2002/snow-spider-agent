WITH level2 AS (
  -- all Level-2 imaging files produced by the WUSTL center
  SELECT
      Imaging_Assay_Type,
      HTAN_Data_File_ID
  FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
  WHERE HTAN_Center = 'HTAN WUSTL'
    AND LOWER(Imaging_Assay_Type) NOT LIKE '%electron mic%'      -- exclude electron microscopy
),
derived AS (
  -- Level-3 / Level-4 files that list the Level-2 file as their parent
  SELECT
      l2.Imaging_Assay_Type,
      CASE
          WHEN LOWER(p.Component) LIKE 'imaginglevel3%' THEN 'Level3'
          WHEN LOWER(p.Component) LIKE 'imaginglevel4%' THEN 'Level4'
      END AS data_level
  FROM level2 AS l2
  JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5` AS p
    ON p.HTAN_Parent_Data_File_ID = l2.HTAN_Data_File_ID
  WHERE p.Component IS NOT NULL
    AND LOWER(p.Component) NOT LIKE '%auxiliary%'
    AND LOWER(p.Component) NOT LIKE '%otherassay%'
    AND (LOWER(p.Component) LIKE 'imaginglevel3%' OR
         LOWER(p.Component) LIKE 'imaginglevel4%')
),
all_levels AS (
  -- include Level-2 plus any higher levels discovered
  SELECT DISTINCT Imaging_Assay_Type, 'Level2' AS data_level FROM level2
  UNION DISTINCT
  SELECT DISTINCT Imaging_Assay_Type, data_level FROM derived
)
SELECT
    Imaging_Assay_Type,
    STRING_AGG(DISTINCT data_level ORDER BY data_level) AS available_levels
FROM all_levels
GROUP BY Imaging_Assay_Type
ORDER BY Imaging_Assay_Type;