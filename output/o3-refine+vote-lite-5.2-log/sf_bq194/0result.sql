WITH files AS (
    SELECT
        "sample_path",
        "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.py'
       OR "sample_path" ILIKE '%.ipynb'
       OR "sample_path" ILIKE '%.r'
       OR "sample_path" ILIKE '%.R'
       OR "sample_path" ILIKE '%.rmd'
       OR "sample_path" ILIKE '%.Rmd'
),
lines AS (
    SELECT
        f."sample_path",
        l.value::string AS line
    FROM files f,
         LATERAL FLATTEN(INPUT => SPLIT(f."content", '\n')) l
),
/* Python/IPython: “from X import …” */
py_from AS (
    SELECT
        REGEXP_SUBSTR(
            line,
            'from\\s+([A-Za-z0-9_.]+)\\s+import',
            1, 1, 'i', 1
        ) AS module
    FROM lines
    WHERE ("sample_path" ILIKE '%.py' OR "sample_path" ILIKE '%.ipynb')
      AND line ILIKE 'from % import %'
),
/* Python/IPython: “import X” */
py_import AS (
    SELECT
        REGEXP_SUBSTR(
            line,
            'import\\s+([A-Za-z0-9_.]+)',
            1, 1, 'i', 1
        ) AS module
    FROM lines
    WHERE ("sample_path" ILIKE '%.py' OR "sample_path" ILIKE '%.ipynb')
      AND line ILIKE 'import %'
),
/* R: library("pkg")  with quotes */
r_library_q AS (
    SELECT
        REGEXP_SUBSTR(
            line,
            'library\\s*\\(\\s*["' || CHR(39) || ']([A-Za-z0-9_.]+)',
            1, 1, 'i', 1
        ) AS module
    FROM lines
    WHERE ("sample_path" ILIKE '%.r'  OR "sample_path" ILIKE '%.R'
           OR "sample_path" ILIKE '%.rmd' OR "sample_path" ILIKE '%.Rmd')
      AND line ILIKE 'library(%'
),
/* R: library(pkg)  without quotes */
r_library_nq AS (
    SELECT
        REGEXP_SUBSTR(
            line,
            'library\\s*\\(\\s*([A-Za-z0-9_.]+)',
            1, 1, 'i', 1
        ) AS module
    FROM lines
    WHERE ("sample_path" ILIKE '%.r'  OR "sample_path" ILIKE '%.R'
           OR "sample_path" ILIKE '%.rmd' OR "sample_path" ILIKE '%.Rmd')
      AND line ILIKE 'library(%'
),
/* R: require("pkg") with quotes */
r_require_q AS (
    SELECT
        REGEXP_SUBSTR(
            line,
            'require\\s*\\(\\s*["' || CHR(39) || ']([A-Za-z0-9_.]+)',
            1, 1, 'i', 1
        ) AS module
    FROM lines
    WHERE ("sample_path" ILIKE '%.r'  OR "sample_path" ILIKE '%.R'
           OR "sample_path" ILIKE '%.rmd' OR "sample_path" ILIKE '%.Rmd')
      AND line ILIKE 'require(%'
),
/* R: require(pkg) without quotes */
r_require_nq AS (
    SELECT
        REGEXP_SUBSTR(
            line,
            'require\\s*\\(\\s*([A-Za-z0-9_.]+)',
            1, 1, 'i', 1
        ) AS module
    FROM lines
    WHERE ("sample_path" ILIKE '%.r'  OR "sample_path" ILIKE '%.R'
           OR "sample_path" ILIKE '%.rmd' OR "sample_path" ILIKE '%.Rmd')
      AND line ILIKE 'require(%'
),
/* Collect all extracted modules */
all_modules AS (
    SELECT LOWER(module) AS module FROM py_from       WHERE module IS NOT NULL
    UNION ALL
    SELECT LOWER(module)        FROM py_import      WHERE module IS NOT NULL
    UNION ALL
    SELECT LOWER(module)        FROM r_library_q    WHERE module IS NOT NULL
    UNION ALL
    SELECT LOWER(module)        FROM r_library_nq   WHERE module IS NOT NULL
    UNION ALL
    SELECT LOWER(module)        FROM r_require_q    WHERE module IS NOT NULL
    UNION ALL
    SELECT LOWER(module)        FROM r_require_nq   WHERE module IS NOT NULL
),
/* Frequency count */
freq AS (
    SELECT
        module,
        COUNT(*) AS cnt
    FROM all_modules
    GROUP BY module
)
/* Pick the 2nd most frequent module */
SELECT module
FROM (
    SELECT
        module,
        cnt,
        ROW_NUMBER() OVER (ORDER BY cnt DESC NULLS LAST, module) AS rn
    FROM freq
)
WHERE rn = 2;