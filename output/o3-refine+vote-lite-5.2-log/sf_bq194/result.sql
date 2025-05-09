WITH code_files AS (
    SELECT
        "content",
        "sample_path"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  LOWER("sample_path") LIKE '%.py'
        OR LOWER("sample_path") LIKE '%.r'
        OR LOWER("sample_path") LIKE '%.rmd'
        OR LOWER("sample_path") LIKE '%.ipynb'
),
lines AS (
    SELECT
        "sample_path",
        f.value::STRING AS line
    FROM code_files,
         LATERAL FLATTEN(input => SPLIT("content", '\n')) f
),
imports AS (
    SELECT
        /* Python/Notebook:  import xxx   OR  from xxx import yyy  (capture group 2) */
        COALESCE(
            REGEXP_SUBSTR(
                line,
                '^\\s*(from|import)\\s+([A-Za-z_][A-Za-z0-9_.]*)',
                1, 1, 'i', 2
            ),
            /* R:  library(xxx)  OR  require(xxx)   (capture group 2) */
            REGEXP_SUBSTR(
                line,
                '\\b(library|require)\\s*\\(\\s*[^A-Za-z0-9_.]*([A-Za-z0-9_.]+)',
                1, 1, 'i', 2
            )
        ) AS module
    FROM lines
),
module_counts AS (
    SELECT
        LOWER(SPLIT_PART(module, '.', 1)) AS module_root,   -- keep only root (e.g., pandas.core -> pandas)
        COUNT(*)                          AS freq
    FROM imports
    WHERE module IS NOT NULL
    GROUP BY module_root
),
ordered AS (
    SELECT
        module_root,
        freq,
        ROW_NUMBER() OVER (ORDER BY freq DESC NULLS LAST, module_root) AS rn
    FROM module_counts
)
SELECT module_root
FROM ordered
WHERE rn = 2;