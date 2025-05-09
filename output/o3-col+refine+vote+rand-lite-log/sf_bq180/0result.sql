SELECT
  "module",
  COUNT(*) AS "use_count"
FROM (
  /* Python: `import module` */
  SELECT
    REGEXP_REPLACE(
      REGEXP_SUBSTR("content",
                    'import\\s+[A-Za-z0-9_\\.]+',
                    1, 1, 'i'),
      'import\\s+',
      ''
    ) AS "module"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
  WHERE "sample_path" ILIKE '%.py'
    AND "content"     ILIKE '%import %'

  UNION ALL

  /* Python: `from module import …` */
  SELECT
    REGEXP_REPLACE(
      REGEXP_SUBSTR("content",
                    'from\\s+[A-Za-z0-9_\\.]+\\s+import',
                    1, 1, 'i'),
      'from\\s+|\\s+import',
      ''
    ) AS "module"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
  WHERE "sample_path" ILIKE '%.py'
    AND "content"     ILIKE '%from %import%'

  UNION ALL

  /* R: library(module) */
  SELECT
    REGEXP_REPLACE(
      REGEXP_SUBSTR("content",
                    'library\\s*\\(\\s*[A-Za-z0-9_\\.]+\\s*\\)',
                    1, 1, 'i'),
      'library\\s*\\(\\s*|\\s*\\)',
      ''
    ) AS "module"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"
  WHERE "sample_path" ILIKE '%.r'
    AND "content"     ILIKE '%library(%'
) AS modules
WHERE "module" IS NOT NULL
GROUP BY "module"
ORDER BY "use_count" DESC NULLS LAST
LIMIT 5;