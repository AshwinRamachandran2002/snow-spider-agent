WITH
/* ---------- Python imports ---------- */
PY AS (
    SELECT
        REGEXP_SUBSTR(
            line.value,
            '^[[:space:]]*(from|import)[[:space:]]+([A-Za-z0-9_.]+)',
            1,                      -- start position
            1,                      -- first occurrence
            'i',                    -- case-insensitive
            2                       -- return 2nd capture group (module name)
        ) AS "package"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
          ON f."id" = c."id",
          LATERAL SPLIT_TO_TABLE(c."content", '\n')  line
    WHERE f."path" ILIKE '%.py'
),
/* ---------- R libraries ---------- */
R AS (
    SELECT
        REGEXP_SUBSTR(
            line.value,
            'library[[:space:]]*\\([[:space:]]*([A-Za-z0-9_.]+)',
            1,
            1,
            'i',
            1                       -- 1st capture group (library name)
        ) AS "package"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
          ON f."id" = c."id",
          LATERAL SPLIT_TO_TABLE(c."content", '\n')  line
    WHERE f."path" ILIKE '%.r'
)
/* ---------- aggregate & present ---------- */
SELECT  'Python'        AS "language",
        "package",
        COUNT(*)        AS "occurrences"
FROM    PY
WHERE   "package" IS NOT NULL
GROUP BY "package"

UNION ALL

SELECT  'R'             AS "language",
        "package",
        COUNT(*)        AS "occurrences"
FROM    R
WHERE   "package" IS NOT NULL
GROUP BY "package"

ORDER BY "language",
         "occurrences" DESC NULLS LAST;