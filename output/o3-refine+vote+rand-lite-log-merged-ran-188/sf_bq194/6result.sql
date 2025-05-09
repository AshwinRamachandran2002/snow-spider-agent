WITH modules AS (

    /* ---------- Python files (.py) ---------- */
    SELECT
        LOWER(
            REGEXP_REPLACE(       -- strip any quotes that may be inside R calls later
                REGEXP_SUBSTR("content",
                              '\\bimport\\s+([A-Za-z0-9_\\.]+)',
                              1, 1, 'e', 1),
                '[\'"]', '')
        )  AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.py'

    UNION ALL

    SELECT
        LOWER(
            REGEXP_SUBSTR("content",
                          '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import',
                          1, 1, 'e', 1)
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.py'


    /* ---------- R files (.r / .R / .Rmd / .rmd) ---------- */
    UNION ALL

    SELECT
        LOWER(
            REGEXP_REPLACE(
                REGEXP_SUBSTR("content",
                              'library\\(([^)]+)\\)',
                              1, 1, 'e', 1),
                '[\'" ]', '')
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.r%'    -- catches all R-related extensions

    UNION ALL

    SELECT
        LOWER(
            REGEXP_REPLACE(
                REGEXP_SUBSTR("content",
                              'require\\(([^)]+)\\)',
                              1, 1, 'e', 1),
                '[\'" ]', '')
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE LOWER("sample_path") LIKE '%.r%'


    /* ---------- Jupyter notebooks (.ipynb) ---------- */
    UNION ALL

    SELECT
        LOWER(
            REGEXP_SUBSTR("content",
                          '\\bimport\\s+([A-Za-z0-9_\\.]+)',
                          1, 1, 'e', 1)
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.ipynb'

    UNION ALL

    SELECT
        LOWER(
            REGEXP_SUBSTR("content",
                          '\\bfrom\\s+([A-Za-z0-9_\\.]+)\\s+import',
                          1, 1, 'e', 1)
        ) AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "sample_path" ILIKE '%.ipynb'

)

SELECT module
FROM (
    SELECT
        module,
        COUNT(*) AS freq,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS rn
    FROM modules
    WHERE module IS NOT NULL AND module <> ''
    GROUP BY module
)
WHERE rn = 2;