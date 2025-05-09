WITH
  species_list AS (
    SELECT DISTINCT UPPER(TRIM(spc_latin)) AS Latin_Name
    FROM `bigquery-public-data.new_york.tree_census_1995`
    WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
    UNION ALL
    SELECT DISTINCT UPPER(TRIM(spc_latin)) AS Latin_Name
    FROM `bigquery-public-data.new_york.tree_census_2005`
    WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
    UNION ALL
    SELECT DISTINCT UPPER(TRIM(spc_latin)) AS Latin_Name
    FROM `bigquery-public-data.new_york.tree_census_2015`
    WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
  ),
  distinct_species AS (
    SELECT DISTINCT Latin_Name FROM species_list
  ),
  counts_1995 AS (
    SELECT
      CASE
        WHEN UPPER(TRIM(spc_latin)) = 'PLATANUS ACERIFOLIA' THEN 'PLATANUS X ACERIFOLIA'
        WHEN UPPER(TRIM(spc_latin)) = 'GLEDITSIA TRIACANTHOS' THEN 'GLEDITSIA TRIACANTHOS VAR. INERMIS'
        WHEN UPPER(TRIM(spc_latin)) = 'SOPHORA JAPONICA' THEN 'STYPHNOLOBIUM JAPONICUM'
        WHEN UPPER(TRIM(spc_latin)) LIKE 'PRUNUS%' THEN 'PRUNUS'
        WHEN UPPER(TRIM(spc_latin)) LIKE 'ACER%' THEN 'ACER'
        ELSE UPPER(TRIM(spc_latin))
      END AS Latin_Name,
      SUM(CASE WHEN status NOT IN ('Dead', 'Stump', 'Dead ', 'Stump ', '') THEN 1 ELSE 0 END) AS Alive_1995,
      SUM(CASE WHEN status IN ('Dead', 'Dead ') THEN 1 ELSE 0 END) AS Dead_1995,
      COUNT(*) AS Total_1995
    FROM `bigquery-public-data.new_york.tree_census_1995`
    WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
    GROUP BY Latin_Name
  ),
  counts_2005 AS (
    SELECT
      CASE
        WHEN UPPER(TRIM(spc_latin)) = 'PLATANUS ACERIFOLIA' THEN 'PLATANUS X ACERIFOLIA'
        WHEN UPPER(TRIM(spc_latin)) = 'GLEDITSIA TRIACANTHOS' THEN 'GLEDITSIA TRIACANTHOS VAR. INERMIS'
        WHEN UPPER(TRIM(spc_latin)) = 'SOPHORA JAPONICA' THEN 'STYPHNOLOBIUM JAPONICUM'
        WHEN UPPER(TRIM(spc_latin)) LIKE 'PRUNUS%' THEN 'PRUNUS'
        WHEN UPPER(TRIM(spc_latin)) LIKE 'ACER%' THEN 'ACER'
        ELSE UPPER(TRIM(spc_latin))
      END AS Latin_Name,
      SUM(CASE WHEN status NOT IN ('Dead', 'Stump', 'Dead ', 'Stump ', '') THEN 1 ELSE 0 END) AS Alive_2005,
      SUM(CASE WHEN status IN ('Dead', 'Dead ') THEN 1 ELSE 0 END) AS Dead_2005,
      COUNT(*) AS Total_2005
    FROM `bigquery-public-data.new_york.tree_census_2005`
    WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
    GROUP BY Latin_Name
  ),
  counts_2015 AS (
    SELECT
      CASE
        WHEN UPPER(TRIM(spc_latin)) LIKE 'PRUNUS%' THEN 'PRUNUS'
        WHEN UPPER(TRIM(spc_latin)) LIKE 'ACER%' THEN 'ACER'
        ELSE UPPER(TRIM(spc_latin))
      END AS Latin_Name,
      spc_common AS Common_Name,
      SUM(CASE WHEN status = 'Alive' THEN 1 ELSE 0 END) AS Alive_2015,
      SUM(CASE WHEN status = 'Dead' THEN 1 ELSE 0 END) AS Dead_2015,
      COUNT(*) AS Total_2015
    FROM `bigquery-public-data.new_york.tree_census_2015`
    WHERE spc_latin IS NOT NULL AND TRIM(spc_latin) != ''
    GROUP BY Latin_Name, Common_Name
  ),
  species_names AS (
    SELECT
      UPPER(TRIM(species_scientific_name)) AS Latin_Name,
      species_common_name AS Common_Name
    FROM `bigquery-public-data.new_york.tree_species`
    WHERE species_scientific_name IS NOT NULL AND TRIM(species_scientific_name) != ''
  )
SELECT
  sl.Latin_Name,
  COALESCE(c15.Common_Name, sn.Common_Name) AS Common_Name,
  (COALESCE(c95.Total_1995, 0) + COALESCE(c05.Total_2005, 0) + COALESCE(c15.Total_2015, 0)) AS Total_Trees,
  COALESCE(c95.Alive_1995, 0) AS Alive_1995,
  COALESCE(c95.Dead_1995, 0) AS Dead_1995,
  COALESCE(c05.Alive_2005, 0) AS Alive_2005,
  COALESCE(c05.Dead_2005, 0) AS Dead_2005,
  COALESCE(c15.Alive_2015, 0) AS Alive_2015,
  COALESCE(c15.Dead_2015, 0) AS Dead_2015,
  (COALESCE(c15.Total_2015, 0) - COALESCE(c95.Total_1995, 0)) AS Growth_in_Total_Trees
FROM distinct_species sl
LEFT JOIN counts_1995 c95 ON sl.Latin_Name = c95.Latin_Name
LEFT JOIN counts_2005 c05 ON sl.Latin_Name = c05.Latin_Name
LEFT JOIN counts_2015 c15 ON sl.Latin_Name = c15.Latin_Name
LEFT JOIN species_names sn ON sl.Latin_Name = sn.Latin_Name
ORDER BY Growth_in_Total_Trees DESC
LIMIT 10;