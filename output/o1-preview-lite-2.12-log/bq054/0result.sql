SELECT 
  COALESCE(t1995.Latin_Name, t2005.Latin_Name, t2015.Latin_Name) AS Latin_Name,
  COALESCE(t1995.Common_Name, t2005.Common_Name, t2015.Common_Name) AS Common_Name,
  COALESCE(t1995.Total_Trees_1995, 0) + COALESCE(t2005.Total_Trees_2005, 0) + COALESCE(t2015.Total_Trees_2015, 0) AS Total_Trees,
  COALESCE(t1995.Alive_1995, 0) AS Alive_1995,
  COALESCE(t1995.Dead_1995, 0) AS Dead_1995,
  COALESCE(t2005.Alive_2005, 0) AS Alive_2005,
  COALESCE(t2005.Dead_2005, 0) AS Dead_2005,
  COALESCE(t2015.Alive_2015, 0) AS Alive_2015,
  COALESCE(t2015.Dead_2015, 0) AS Dead_2015,
  (COALESCE(t2015.Total_Trees_2015, 0) - COALESCE(t1995.Total_Trees_1995, 0)) AS Growth_in_Total_Trees
FROM (
  SELECT
    UPPER(spc_latin) AS Latin_Name,
    ANY_VALUE(spc_common) AS Common_Name,
    COUNT(*) AS Total_Trees_1995,
    SUM(CASE WHEN status IN ('Good', 'Fair', 'Poor') THEN 1 ELSE 0 END) AS Alive_1995,
    SUM(CASE WHEN status IN ('Dead', 'Stump') THEN 1 ELSE 0 END) AS Dead_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE spc_latin IS NOT NULL AND spc_latin != ''
  GROUP BY Latin_Name
) AS t1995
FULL OUTER JOIN (
  SELECT
    UPPER(spc_latin) AS Latin_Name,
    ANY_VALUE(spc_common) AS Common_Name,
    COUNT(*) AS Total_Trees_2005,
    SUM(CASE WHEN status IN ('Good', 'Fair', 'Poor') THEN 1 ELSE 0 END) AS Alive_2005,
    SUM(CASE WHEN status IN ('Dead', 'Stump') THEN 1 ELSE 0 END) AS Dead_2005
  FROM `bigquery-public-data.new_york.tree_census_2005`
  WHERE spc_latin IS NOT NULL AND spc_latin != ''
  GROUP BY Latin_Name
) AS t2005
ON t1995.Latin_Name = t2005.Latin_Name
FULL OUTER JOIN (
  SELECT
    UPPER(spc_latin) AS Latin_Name,
    ANY_VALUE(spc_common) AS Common_Name,
    COUNT(*) AS Total_Trees_2015,
    SUM(CASE WHEN LOWER(status) = 'alive' THEN 1 ELSE 0 END) AS Alive_2015,
    SUM(CASE WHEN LOWER(status) = 'dead' THEN 1 ELSE 0 END) AS Dead_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND spc_latin != ''
  GROUP BY Latin_Name
) AS t2015
ON COALESCE(t1995.Latin_Name, t2005.Latin_Name) = t2015.Latin_Name
ORDER BY Growth_in_Total_Trees DESC
LIMIT 10;