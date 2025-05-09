/*-----------------------------------------------------------
  SECOND-most frequently imported / loaded module or package
  across Python (.py), R (.r/.R/.rmd/.Rmd) and Jupyter (.ipynb)
  files in GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
-----------------------------------------------------------*/
WITH all_modules AS (

    /* -------- Python files :  import X ------------------------- */
    SELECT
        REGEXP_SUBSTR(f.value::STRING,
                      '^import\\s+([A-Za-z0-9_\\.]+)',
                      1, 1, 'e', 1)          AS module
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE c."sample_path" ILIKE '%.py'
      AND f.value::STRING ILIKE 'import %'

    UNION ALL

    /* -------- Python files :  from X import … ------------------ */
    SELECT
        REGEXP_SUBSTR(f.value::STRING,
                      '^from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                      1, 1, 'e', 1)
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE c."sample_path" ILIKE '%.py'
      AND f.value::STRING ILIKE 'from % import %'

    UNION ALL

    /* -------- R files :  library(pkg) -------------------------- */
    SELECT
        REGEXP_SUBSTR(f.value::STRING,
                      '\\blibrary\\(\\s*([A-Za-z0-9\\.]+)',
                      1, 1, 'e', 1)
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE (c."sample_path" ILIKE '%.r'
           OR c."sample_path" ILIKE '%.R'
           OR c."sample_path" ILIKE '%.rmd'
           OR c."sample_path" ILIKE '%.Rmd')
      AND f.value::STRING ILIKE '%library(%'

    UNION ALL

    /* -------- R files :  require(pkg) -------------------------- */
    SELECT
        REGEXP_SUBSTR(f.value::STRING,
                      '\\brequire\\(\\s*([A-Za-z0-9\\.]+)',
                      1, 1, 'e', 1)
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE (c."sample_path" ILIKE '%.r'
           OR c."sample_path" ILIKE '%.R'
           OR c."sample_path" ILIKE '%.rmd'
           OR c."sample_path" ILIKE '%.Rmd')
      AND f.value::STRING ILIKE '%require(%'

    UNION ALL

    /* -------- Jupyter notebooks :  import X -------------------- */
    SELECT
        REGEXP_SUBSTR(f.value::STRING,
                      '["'']?import\\s+([A-Za-z0-9_\\.]+)',
                      1, 1, 'e', 1)
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE c."sample_path" ILIKE '%.ipynb'
      AND f.value::STRING ILIKE '%import %'

    UNION ALL

    /* -------- Jupyter notebooks :  from X import … ------------- */
    SELECT
        REGEXP_SUBSTR(f.value::STRING,
                      '["'']?from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                      1, 1, 'e', 1)
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE c."sample_path" ILIKE '%.ipynb'
      AND f.value::STRING ILIKE '%from % import %'

), module_counts AS (
    SELECT
        module,
        COUNT(*) AS cnt
    FROM all_modules
    WHERE module IS NOT NULL
    GROUP BY module
), ranked AS (
    SELECT
        module,
        cnt,
        ROW_NUMBER() OVER (ORDER BY cnt DESC NULLS LAST) AS rn
    FROM module_counts
)
SELECT
    module,
    cnt AS occurrences
FROM ranked
WHERE rn = 2;