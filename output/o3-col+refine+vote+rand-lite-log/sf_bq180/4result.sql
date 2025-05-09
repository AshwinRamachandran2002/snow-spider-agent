SELECT
  "module_name",
  COUNT(*) AS "occurrences"
FROM (
    /* ---------- Python: plain `import …` ---------- */
    SELECT
      REGEXP_SUBSTR("content",
                    'import\\s+([A-Za-z0-9_]+)',
                    1, 1, 'e', 1) AS "module_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.py'
      AND "content" ILIKE '%import %'

    UNION ALL

    /* ---------- Python: `from … import …` ---------- */
    SELECT
      REGEXP_SUBSTR("content",
                    'from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                    1, 1, 'e', 1) AS "module_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.py'
      AND "content" ILIKE '%from %import%'

    UNION ALL

    /* ---------- R: `library(…)` ---------- */
    SELECT
      REGEXP_SUBSTR("content",
                    'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                    1, 1, 'e', 1) AS "module_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.r'
      AND "content" ILIKE '%library(%'
) AS modules
WHERE "module_name" IS NOT NULL
GROUP BY "module_name"
ORDER BY "occurrences" DESC NULLS LAST
LIMIT 5;