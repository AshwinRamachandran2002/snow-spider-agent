-- Imaging assay-types at HTAN WUSTL (r5) that have Level-2 data
-- and any higher–level (Level-3 / Level-4) data whose entityIds
-- are recorded in `id_provenance_r5`.  Auxiliary / OtherAssay
-- Components and Electron-microscopy assays are excluded.

WITH level2 AS (
    SELECT
        HTAN_Data_File_ID,
        Imaging_Assay_Type
    FROM `isb-cgc-bq.HTAN_versioned.imaging_level2_metadata_r5`
    WHERE HTAN_Center = 'HTAN WUSTL'
      AND LOWER(Component) = 'imaginglevel2'
      AND Imaging_Assay_Type IS NOT NULL
      AND NOT REGEXP_CONTAINS(LOWER(Imaging_Assay_Type), r'electron')  -- drop EM assays
),

-- flag that Level-2 exists (always true for rows above)
lvl2_flag AS (
    SELECT DISTINCT
        Imaging_Assay_Type,
        'Level2' AS level
    FROM level2
),

-- Level-3 data that can be linked back to a WUSTL Level-2 file
-- through its parent HTAN_Data_File_ID and whose entityId is
-- present in id_provenance_r5
lvl3_flag AS (
    SELECT DISTINCT
        l2.Imaging_Assay_Type,
        'Level3' AS level
    FROM `isb-cgc-bq.HTAN_versioned.imaging_level3_segmentation_metadata_r3` AS seg
    JOIN level2                        AS l2   ON seg.HTAN_Parent_Data_File_ID = l2.HTAN_Data_File_ID
    JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5`      AS prov ON prov.entityId = seg.entityId
    WHERE prov.HTAN_Center = 'HTAN WUSTL'
      AND prov.Component IS NOT NULL
      AND LOWER(prov.Component) LIKE 'imaginglevel3%'
      AND LOWER(prov.Component) NOT LIKE '%auxiliary%'
      AND LOWER(prov.Component) NOT LIKE '%otherassay%'
),

-- Level-4 data that can be linked back to a WUSTL Level-2 file
-- and whose entityId also appears in id_provenance_r5
lvl4_flag AS (
    SELECT DISTINCT
        l2.Imaging_Assay_Type,
        'Level4' AS level
    FROM `isb-cgc-bq.HTAN_versioned.imaging_level4_metadata_r5` AS lev4
    JOIN level2                        AS l2   ON lev4.HTAN_Parent_Data_File_ID = l2.HTAN_Data_File_ID
    JOIN `isb-cgc-bq.HTAN_versioned.id_provenance_r5`      AS prov ON prov.entityId = lev4.entityId
    WHERE prov.HTAN_Center = 'HTAN WUSTL'
      AND prov.Component IS NOT NULL
      AND LOWER(prov.Component) LIKE 'imaginglevel4%'
      AND LOWER(prov.Component) NOT LIKE '%auxiliary%'
      AND LOWER(prov.Component) NOT LIKE '%otherassay%'
),

-- unify the three level flags
all_levels AS (
    SELECT * FROM lvl2_flag
    UNION ALL
    SELECT * FROM lvl3_flag
    UNION ALL
    SELECT * FROM lvl4_flag
)

-- final report
SELECT
    Imaging_Assay_Type,
    ARRAY_AGG(DISTINCT level ORDER BY level) AS available_levels
FROM all_levels
GROUP BY Imaging_Assay_Type
ORDER BY Imaging_Assay_Type;