SELECT
  "Language",
  "Module_or_Library",
  "Count"
FROM (
  SELECT
    'Python' AS "Language",
    LOWER(REGEXP_SUBSTR(line.value, '^\\s*(import|from)\\s+([\\w\\.]+)', 1, 1, 'i', 2)) AS "Module_or_Library",
    COUNT(*) AS "Count"
  FROM
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
  JOIN
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
      ON f."id" = c."id",
    LATERAL FLATTEN(input => SPLIT(c."content", '\n')) AS line
  WHERE
    f."path" ILIKE '%.py'
    AND REGEXP_LIKE(line.value, '^\\s*(import|from)\\s+[\\w\\.]+', 'i')
    AND REGEXP_SUBSTR(line.value, '^\\s*(import|from)\\s+([\\w\\.]+)', 1, 1, 'i', 2) IS NOT NULL
  GROUP BY
    "Language",
    LOWER(REGEXP_SUBSTR(line.value, '^\\s*(import|from)\\s+([\\w\\.]+)', 1, 1, 'i', 2))

  UNION ALL

  SELECT
    'R' AS "Language",
    LOWER(REGEXP_SUBSTR(line.value, 'library\\s*\\(\\s*([^)\\s]+)\\s*\\)', 1, 1, 'i', 1)) AS "Module_or_Library",
    COUNT(*) AS "Count"
  FROM
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" f
  JOIN
    "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c
      ON f."id" = c."id",
    LATERAL FLATTEN(input => SPLIT(c."content", '\n')) AS line
  WHERE
    f."path" ILIKE '%.r'
    AND REGEXP_LIKE(line.value, 'library\\s*\\(\\s*([^)\\s]+)\\s*\\)', 'i')
    AND REGEXP_SUBSTR(line.value, 'library\\s*\\(\\s*([^)\\s]+)\\s*\\)', 1, 1, 'i', 1) IS NOT NULL
  GROUP BY
    "Language",
    LOWER(REGEXP_SUBSTR(line.value, 'library\\s*\\(\\s*([^)\\s]+)\\s*\\)', 1, 1, 'i', 1))
) AS combined_results
ORDER BY
  "Language",
  "Count" DESC NULLS LAST
LIMIT 100;