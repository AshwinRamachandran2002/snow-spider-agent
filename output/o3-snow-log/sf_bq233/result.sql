WITH python_packages AS (
    SELECT
        REGEXP_SUBSTR(
            s.value,
            '(from|import)\\s+([A-Za-z_][A-Za-z0-9_\\.]+)',
            1, 1, 'i', 2      -- capture group 2 = module name
        ) AS "package"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON f."id" = c."id"
    ,     LATERAL SPLIT_TO_TABLE(REGEXP_REPLACE(c."content", '\r', ''), '\n') s
    WHERE LOWER(f."path") LIKE '%.py'
      AND s.value ILIKE '%import%'
      AND REGEXP_SUBSTR(
            s.value,
            '(from|import)\\s+([A-Za-z_][A-Za-z0-9_\\.]+)',
            1, 1, 'i', 2
          ) IS NOT NULL
),
r_packages AS (
    SELECT
        REGEXP_SUBSTR(
            s.value,
            'library\\s*\\(\\s*([A-Za-z0-9_.]+)',
            1, 1, 'i', 1      -- capture group 1 = library name
        ) AS "package"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
      ON f."id" = c."id"
    ,     LATERAL SPLIT_TO_TABLE(REGEXP_REPLACE(c."content", '\r', ''), '\n') s
    WHERE LOWER(f."path") LIKE '%.r'
      AND s.value ILIKE '%library(%'
      AND REGEXP_SUBSTR(
            s.value,
            'library\\s*\\(\\s*([A-Za-z0-9_.]+)',
            1, 1, 'i', 1
          ) IS NOT NULL
)
SELECT
    'Python' AS "language",
    "package",
    COUNT(*) AS "occurrences"
FROM python_packages
GROUP BY "package"

UNION ALL

SELECT
    'R'      AS "language",
    "package",
    COUNT(*) AS "occurrences"
FROM r_packages
GROUP BY "package"

ORDER BY "language", "occurrences" DESC NULLS LAST;