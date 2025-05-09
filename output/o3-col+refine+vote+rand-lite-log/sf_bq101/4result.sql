WITH imports AS (
  SELECT
    REGEXP_SUBSTR(
      l.value,
      'import\\s+(static\\s+)?([A-Za-z0-9_]+(\\.[A-Za-z0-9_]+)*)',
      1, 1, 'e', 2
    ) AS "imported_package"
  FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS t,
       LATERAL SPLIT_TO_TABLE(t."content", '\n') AS l
  WHERE t."sample_path" ILIKE '%.java'
    AND l.value ILIKE 'import %'
)
SELECT
  "imported_package",
  COUNT(*) AS "cnt"
FROM imports
WHERE "imported_package" IS NOT NULL
GROUP BY "imported_package"
ORDER BY "cnt" DESC NULLS LAST
LIMIT 10;