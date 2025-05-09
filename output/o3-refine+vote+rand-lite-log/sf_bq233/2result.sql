WITH py_r_files AS (
    SELECT
        f."repo_name",
        f."path",
        c."content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES f
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
        ON f."id" = c."id"
    WHERE LOWER(f."path") LIKE '%.py'
       OR LOWER(f."path") LIKE '%.r'
),
lines AS (
    SELECT
        prf."repo_name",
        prf."path",
        CASE WHEN LOWER(prf."path") LIKE '%.py' THEN 'python' ELSE 'r' END AS "language",
        t.value AS "line"
    FROM py_r_files prf,
         LATERAL SPLIT_TO_TABLE(prf."content", '\n') t
),
py_imports AS (
    SELECT
        "language",
        COALESCE(
            REGEXP_SUBSTR("line", '^\\s*import\\s+([A-Za-z0-9_\\.]+)', 1, 1, 'i', 1),
            REGEXP_SUBSTR("line", '^\\s*from\\s+([A-Za-z0-9_\\.]+)\\s+import', 1, 1, 'i', 1)
        ) AS "module"
    FROM lines
    WHERE "language" = 'python'
),
r_libs AS (
    SELECT
        "language",
        REGEXP_SUBSTR(
            "line",
            $$library\s*\(\s*["']?([A-Za-z0-9_\.]+)["']?\s*\)$$,
            1, 1, 'i', 1
        ) AS "module"
    FROM lines
    WHERE "language" = 'r'
),
all_modules AS (
    SELECT 'python' AS "language", "module" FROM py_imports
    UNION ALL
    SELECT 'r'      AS "language", "module" FROM r_libs
)
SELECT
    "language",
    "module",
    COUNT(*) AS "occurrences"
FROM all_modules
WHERE "module" IS NOT NULL
GROUP BY "language", "module"
ORDER BY "language", "occurrences" DESC NULLS LAST, "module";