WITH extracted AS (

    /* -------- Python  &  Jupyter-Notebook files -------- */
    SELECT
        REGEXP_SUBSTR("content", '\\bimport\\s+([A-Za-z0-9_]+)', 1, 1, 'm', 1)   AS "lib_name"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.py'
       OR "sample_path" ILIKE '%.ipynb'

    UNION ALL

    /* ------------------------  R files  ------------------------ */
    SELECT
        REGEXP_SUBSTR("content",
                      '(library|require)\\s*\\(\\s*([A-Za-z0-9._]+)',
                      1, 1, 'm', 2)                                             AS "lib_name"
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.r'
       OR "sample_path" ILIKE '%.R'
       OR "sample_path" ILIKE '%.rmd'
       OR "sample_path" ILIKE '%.Rmd'
)

, freq AS (
    SELECT
        "lib_name",
        COUNT(*) AS "total_occurrences"
    FROM extracted
    WHERE "lib_name" IS NOT NULL
    GROUP BY "lib_name"
)

, ranked AS (
    SELECT
        "lib_name",
        "total_occurrences",
        ROW_NUMBER() OVER (ORDER BY "total_occurrences" DESC NULLS LAST) AS rk
    FROM freq
)

SELECT
    "lib_name",
    "total_occurrences"
FROM ranked
WHERE rk = 2;