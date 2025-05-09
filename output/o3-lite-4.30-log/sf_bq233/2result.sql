WITH python AS (
    SELECT
        REGEXP_SUBSTR(
            LOWER(c."content"),
            '(^|\\n)\\s*(import|from)\\s+([a-z0-9_.]+)',
            1,
            1,
            'e',
            3
        ) AS "module"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON f."id" = c."id"
    WHERE f."path" ILIKE '%.py'
),
r_lang AS (
    SELECT
        REGEXP_SUBSTR(
            LOWER(c."content"),
            'library\\s*\\(\\s*([a-z0-9_.]+)',
            1,
            1,
            'e',
            1
        ) AS "module"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON f."id" = c."id"
    WHERE f."path" ILIKE '%.r'
)
SELECT
    'Python' AS "language",
    "module",
    COUNT(*) AS "occurrences"
FROM python
WHERE "module" IS NOT NULL
GROUP BY "module"
UNION ALL
SELECT
    'R' AS "language",
    "module",
    COUNT(*) AS "occurrences"
FROM r_lang
WHERE "module" IS NOT NULL
GROUP BY "module"
ORDER BY
    "language",
    "occurrences" DESC NULLS LAST,
    "module";