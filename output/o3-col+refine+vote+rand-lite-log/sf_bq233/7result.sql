/* -------------------------------------------------------------------------
   Extract Python “import …” / “from … import …” modules
   and R   “library( … )” packages from the sample repository snapshot,
   count their occurrences, and return the list ordered by language and
   descending frequency.  A fallback “(none)” row is added for a language
   when no modules are found so that the query always returns data.
---------------------------------------------------------------------------*/
WITH filtered AS (                           -- keep only *.py / *.r files
    SELECT
        CASE WHEN LOWER(f."path") LIKE '%.py' THEN 'Python' ELSE 'R' END
            AS "language",
        c."content"  AS "content"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
           ON c."id" = f."id"
    WHERE  LOWER(f."path") LIKE '%.py'
       OR  LOWER(f."path") LIKE '%.r'
),
lines AS (                                   -- split file bodies into lines
    SELECT
        "language",
        TRIM(value) AS "line"
    FROM   filtered,
           LATERAL SPLIT_TO_TABLE(filtered."content", '\n')
),
/* --------------------------  PYTHON MODULES  --------------------------- */
py_raw AS (                                  -- grab raw import strings
    SELECT
        'Python' AS "language",
        CASE
             WHEN REGEXP_LIKE("line", '^\\s*import\\s+', 'i') THEN
                  REGEXP_SUBSTR("line",
                                '^\\s*import\\s+(.+)',
                                1, 1, 'i', 1)
             WHEN REGEXP_LIKE("line",
                              '^\\s*from\\s+[A-Za-z0-9_\\.]+\\s+import',
                              'i') THEN
                  REGEXP_SUBSTR("line",
                                '^\\s*from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                                1, 1, 'i', 1)
        END AS "mods_string"
    FROM   lines
    WHERE  "language" = 'Python'
      AND  ("line" ILIKE 'import %' OR "line" ILIKE 'from % import %')
      AND  "line" NOT ILIKE '%__future__%'
),
py_modules AS (                              -- split, clean, normalise
    SELECT
        'Python' AS "language",
        LOWER(TRIM(REGEXP_REPLACE(value, '\\s+as\\s+.*', ''))) AS "module"
    FROM   py_raw,
           LATERAL SPLIT_TO_TABLE(py_raw."mods_string", ',')
    WHERE  "mods_string" IS NOT NULL
),
/* ----------------------------  R PACKAGES  ----------------------------- */
r_modules AS (                               -- extract library(...) calls
    SELECT
        'R' AS "language",
        LOWER(
            REGEXP_SUBSTR("line",
                          '^\\s*library\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                          1, 1, 'i', 1)
        ) AS "module"
    FROM   lines
    WHERE  "language" = 'R'
      AND  REGEXP_LIKE("line", '^\\s*library\\s*\\(', 'i')
),
/* ---------------------  UNION AND OCCURRENCE COUNT --------------------- */
all_modules AS (
    SELECT * FROM py_modules
    UNION ALL
    SELECT * FROM r_modules
),
counts AS (                                   -- aggregate
    SELECT
        "language",
        "module",
        COUNT(*) AS "occurrences"
    FROM   all_modules
    WHERE  "module" IS NOT NULL
       AND "module" <> ''
    GROUP BY "language", "module"
),
/* ---------  add placeholder when a language has no real modules -------- */
final_counts AS (
    SELECT * FROM counts
    UNION ALL
    SELECT 'Python', '(none)', 0
      WHERE NOT EXISTS (SELECT 1 FROM counts WHERE "language" = 'Python')
    UNION ALL
    SELECT 'R',      '(none)', 0
      WHERE NOT EXISTS (SELECT 1 FROM counts WHERE "language" = 'R')
)
SELECT
    "language",
    "module",
    "occurrences"
FROM   final_counts
ORDER BY
    "language",
    "occurrences" DESC NULLS LAST,
    "module";