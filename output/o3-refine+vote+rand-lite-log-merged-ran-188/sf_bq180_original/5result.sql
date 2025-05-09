/* Top‑5 most frequently imported/loaded modules in Python (.py) and R (.r) files */
WITH python_lines AS (
    SELECT
        LOWER(sc."sample_path")      AS path,
        t.value                      AS line
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS" AS sc,
         LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) AS t
    WHERE sc."binary" = FALSE
      AND LOWER(sc."sample_path") LIKE '%.py'
),
r_lines AS (
    SELECT
        t.value AS line
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS" AS sc,
         LATERAL FLATTEN(INPUT => SPLIT(sc."content", '\n')) AS t
    WHERE sc."binary" = FALSE
      AND LOWER(sc."sample_path") LIKE '%.r'
),

/* --------- Python: “import xxx” ---------------- */
py_import AS (
    SELECT
        LOWER(TRIM(
            REGEXP_REPLACE(
                REGEXP_SUBSTR(line, '\\bimport\\s+([A-Za-z0-9_\\.]+)', 1, 1, 'i', 1),
                '\\.$', ''
            )
        )) AS module
    FROM python_lines
    WHERE REGEXP_SUBSTR(line, '\\bimport\\s+([A-Za-z0-9_\\.]+)', 1, 1, 'i', 1) IS NOT NULL
),

/* --------- Python: “from xxx import …” --------- */
py_from AS (
    SELECT
        LOWER(TRIM(
            REGEXP_SUBSTR(line, '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import', 1, 1, 'i', 1)
        )) AS module
    FROM python_lines
    WHERE REGEXP_SUBSTR(line, '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import', 1, 1, 'i', 1) IS NOT NULL
),

/* --------- R:  library(xxx) -------------------- */
r_library AS (
    SELECT
        LOWER(TRIM(
            REGEXP_SUBSTR(line, 'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)\\s*\\)', 1, 1, 'i', 1)
        )) AS module
    FROM r_lines
    WHERE REGEXP_SUBSTR(line, 'library\\s*\\(\\s*([A-Za-z0-9_\\.]+)\\s*\\)', 1, 1, 'i', 1) IS NOT NULL
),

/* --------- Combine all modules ----------------- */
all_modules AS (
    SELECT module FROM py_import
    UNION ALL
    SELECT module FROM py_from
    UNION ALL
    SELECT module FROM r_library
)

SELECT
    module,
    COUNT(*) AS frequency
FROM all_modules
GROUP BY module
ORDER BY frequency DESC NULLS LAST, module
LIMIT 5;