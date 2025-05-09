WITH lines AS (
    SELECT
        c."sample_path"                 AS "path",
        f.value::string                 AS "line"
    FROM "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS" c,
         LATERAL FLATTEN(input => SPLIT(c."content", '\n')) f
),

/* ------------------------ Python: imports & from‑imports ------------------------ */
python_modules AS (
    /* pattern: import <module> */
    SELECT LOWER(REGEXP_SUBSTR("line",
                               '^\\s*import\\s+([A-Za-z0-9_]+)',
                               1, 1, 'e', 1)) AS "module"
    FROM lines
    WHERE "path" ILIKE '%.py'
      AND REGEXP_SUBSTR("line",
                        '^\\s*import\\s+([A-Za-z0-9_]+)',
                        1, 1, 'e', 1) IS NOT NULL

    UNION ALL

    /* pattern: from <module> import … */
    SELECT LOWER(REGEXP_SUBSTR("line",
                               '^\\s*from\\s+([A-Za-z0-9_\\.]+)',
                               1, 1, 'e', 1)) AS "module"
    FROM lines
    WHERE "path" ILIKE '%.py'
      AND REGEXP_SUBSTR("line",
                        '^\\s*from\\s+([A-Za-z0-9_\\.]+)',
                        1, 1, 'e', 1) IS NOT NULL
),

/* ------------------------------ R: library / require ----------------------------- */
r_modules AS (
    SELECT LOWER(REGEXP_SUBSTR("line",
                               '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9\\.]+)',
                               1, 1, 'e', 2)) AS "module"
    FROM lines
    WHERE "path" ILIKE '%.r'
      AND REGEXP_SUBSTR("line",
                        '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9\\.]+)',
                        1, 1, 'e', 2) IS NOT NULL
),

/* ----------------------------- aggregate by language ----------------------------- */
aggregated AS (
    SELECT 'python' AS "language", "module", COUNT(*) AS "occurrences"
    FROM python_modules
    GROUP BY "module"

    UNION ALL

    SELECT 'r'      AS "language", "module", COUNT(*) AS "occurrences"
    FROM r_modules
    GROUP BY "module"
)

/* ---------------------------------- final output ---------------------------------- */
SELECT
    "language",
    "module",
    "occurrences"
FROM aggregated
ORDER BY
    "language",
    "occurrences" DESC NULLS LAST,
    "module";