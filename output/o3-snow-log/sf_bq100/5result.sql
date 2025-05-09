-- Top-10 most frequently used packages in multi-line Go “import (…)” blocks
SELECT
  "package"       AS "package_name",
  COUNT(*)        AS "usage_count"
FROM (
  /* 1) pull the first multi-line import block in each Go source file
     2) split it line-by-line
     3) capture the package path found between double-quotes           */
  SELECT
    REGEXP_SUBSTR(q.value, '\"([^\"]+)\"', 1, 1, 'e', 1) AS "package"
  FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS"  c,
       LATERAL SPLIT_TO_TABLE(
         REGEXP_SUBSTR(c."content", 'import[[:space:]]*\\([^)]*\\)', 1, 1, 'e'),
         '\n'
       )                                            q
  WHERE c."sample_path" ILIKE '%.go'        -- only Go source files
    AND c."content"     ILIKE '%import (%'  -- must contain multi-line import
) t
WHERE "package" IS NOT NULL                  -- drop blank lines & mis-matches
GROUP BY "package"
ORDER BY "usage_count" DESC NULLS LAST
LIMIT 10;