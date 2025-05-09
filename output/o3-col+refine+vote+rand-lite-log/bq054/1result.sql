-- Top-10 tree species: totals & alive/dead counts in 1995 vs 2015 and growth figures
WITH c1995 AS (          -- 1. Aggregate 1995 census by its native 4-letter species code
  SELECT
    UPPER(species) AS code,                       -- e.g. QUPA
    MAX(spc_common) AS common_name_1995,
    COUNT(*) AS total_1995,
    SUM(CASE
          WHEN LOWER(status) IN ('good','excellent','poor','fair',
                                 'fair condition','new','injured')
          THEN 1 END)        AS alive_1995,
    SUM(CASE
          WHEN LOWER(status) IN ('dead','stump','shaft')
          THEN 1 END)        AS dead_1995
  FROM `bigquery-public-data.new_york.tree_census_1995`
  WHERE species IS NOT NULL AND species <> ''
  GROUP BY code
),
c2015 AS (          -- 2. Build equivalent 4-letter code from Latin names and aggregate 2015 census
  SELECT
    CONCAT(
      SUBSTR(SPLIT(UPPER(spc_latin),' ')[OFFSET(0)],1,2),
      SUBSTR(SPLIT(UPPER(spc_latin),' ')[SAFE_OFFSET(1)],1,2)
    )                       AS code,             -- same pattern as 1995 file
    UPPER(spc_latin)        AS latin_name,
    MAX(spc_common)         AS common_name_2015,
    COUNT(*)                AS total_2015,
    SUM(CASE WHEN LOWER(status) = 'alive' THEN 1 END) AS alive_2015,
    SUM(CASE WHEN LOWER(status) IN ('dead','stump') THEN 1 END) AS dead_2015
  FROM `bigquery-public-data.new_york.tree_census_2015`
  WHERE spc_latin IS NOT NULL AND spc_latin <> ''
  GROUP BY code, latin_name
)

-- 3. Join 1995 & 2015 summaries on the 4-letter code, calculate growth, rank & return
SELECT
  c2015.latin_name                                   AS latin_name,
  COALESCE(c2015.common_name_2015,
           c1995.common_name_1995)                   AS common_name,
  total_1995, alive_1995, dead_1995,
  total_2015, alive_2015, dead_2015,
  total_2015 - total_1995   AS diff_total,
  alive_2015 - alive_1995   AS diff_alive,
  dead_2015  - dead_1995    AS diff_dead
FROM c1995
JOIN c2015 USING (code)
ORDER BY diff_total DESC      -- largest growth first
LIMIT 10;