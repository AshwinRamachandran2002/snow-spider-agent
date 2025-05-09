WITH libs AS (

    /* -------- Python  (.py) and Notebook (.ipynb) -------- */
    SELECT
        REGEXP_SUBSTR(
            f.value::STRING,
            '\\b(from|import)\\s+([A-Za-z0-9_\\.]+)',
            1,                      -- start position
            1,                      -- first occurrence
            '',                     -- default parameters
            2                       -- return the 2nd capture group (= module)
        )          AS lib_name
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS t,
         LATERAL FLATTEN(input => SPLIT(t."content", '\n')) f
    WHERE  (LOWER(t."sample_path") LIKE '%.py'
            OR LOWER(t."sample_path") LIKE '%.ipynb')
       AND (f.value ILIKE 'import %'  OR f.value ILIKE 'from % import %')

    UNION ALL

    /* -------- R  (.r, .R, .rmd, .Rmd) -------- */
    SELECT
        REGEXP_SUBSTR(
            f.value::STRING,
            '\\b(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
            1,
            1,
            '',
            2                       -- return the package-name capture group
        )          AS lib_name
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS t,
         LATERAL FLATTEN(input => SPLIT(t."content", '\n')) f
    WHERE  (LOWER(t."sample_path") LIKE '%.r'
            OR LOWER(t."sample_path") LIKE '%.rmd')
       AND (f.value ILIKE 'library(%' OR f.value ILIKE 'require(%')
)

SELECT lib_name
FROM (
    SELECT
        lib_name,
        COUNT(*)                           AS total_mentions,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST) AS rn
    FROM libs
    WHERE lib_name IS NOT NULL
    GROUP BY lib_name
)
WHERE rn = 2;