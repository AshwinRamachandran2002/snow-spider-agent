WITH python_lines AS (
    SELECT  l.value::STRING AS line
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
              ON f."id" = c."id"
    CROSS JOIN LATERAL FLATTEN( INPUT => SPLIT(c."content", '\n') ) l
    WHERE   f."path" ILIKE '%.py'
),
python_modules AS (
    SELECT  REGEXP_SUBSTR(
                line,
                '^\\s*(from|import)\\s+([A-Za-z0-9_.]+)',
                1, 1, 'ie', 2)         AS module
    FROM    python_lines
    WHERE   REGEXP_SUBSTR(
                line,
                '^\\s*(from|import)\\s+([A-Za-z0-9_.]+)',
                1, 1, 'ie') IS NOT NULL
),

r_lines AS (
    SELECT  l.value::STRING AS line
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES    f
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
              ON f."id" = c."id"
    CROSS JOIN LATERAL FLATTEN( INPUT => SPLIT(c."content", '\n') ) l
    WHERE   f."path" ILIKE '%.r'
),
r_modules AS (
    SELECT  REGEXP_SUBSTR(
                line,
                'library\\s*\\(\\s*([A-Za-z0-9_.]+)',
                1, 1, 'ie', 1)         AS module
    FROM    r_lines
    WHERE   REGEXP_SUBSTR(
                line,
                'library\\s*\\(\\s*([A-Za-z0-9_.]+)',
                1, 1, 'ie') IS NOT NULL
)

SELECT  'Python'               AS "language",
        module                 AS "package_or_module",
        COUNT(*)               AS "occurrences"
FROM    python_modules
GROUP BY module

UNION ALL

SELECT  'R'                    AS "language",
        module                 AS "package_or_module",
        COUNT(*)               AS "occurrences"
FROM    r_modules
GROUP BY module

ORDER BY "language",
         "occurrences" DESC NULLS LAST;