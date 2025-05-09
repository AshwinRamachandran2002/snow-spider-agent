WITH python_imports AS (
  SELECT
    'Python' AS "Language",
    REGEXP_SUBSTR(
      sc."content",
      '\\bimport\\s+([a-zA-Z0-9_\\.]+)',
      1, 1, 'i', 1
    ) AS "Module_or_Library"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" sf
  JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc
    ON sc."id" = sf."id"
  WHERE sf."path" ILIKE '%.py'
    AND sc."content" IS NOT NULL
),
python_from_imports AS (
  SELECT
    'Python' AS "Language",
    REGEXP_SUBSTR(
      sc."content",
      '\\bfrom\\s+([a-zA-Z0-9_\\.]+)\\s+import',
      1, 1, 'i', 1
    ) AS "Module_or_Library"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" sf
  JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc
    ON sc."id" = sf."id"
  WHERE sf."path" ILIKE '%.py'
    AND sc."content" IS NOT NULL
),
r_imports AS (
  SELECT
    'R' AS "Language",
    REGEXP_SUBSTR(
      sc."content",
      '\\b(library|require)\\s*\\(\\s*["'']?([a-zA-Z0-9_\\.]+)["'']?\\s*\\)',
      1, 1, 'i', 2
    ) AS "Module_or_Library"
  FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES" sf
  JOIN "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" sc
    ON sc."id" = sf."id"
  WHERE sf."path" ILIKE '%.r'
    AND sc."content" IS NOT NULL
)
SELECT "Language", "Module_or_Library", COUNT(*) AS "Count"
FROM (
  SELECT * FROM python_imports
  UNION ALL
  SELECT * FROM python_from_imports
  UNION ALL
  SELECT * FROM r_imports
) t
WHERE "Module_or_Library" IS NOT NULL
GROUP BY "Language", "Module_or_Library"
ORDER BY "Language", "Count" DESC NULLS LAST;