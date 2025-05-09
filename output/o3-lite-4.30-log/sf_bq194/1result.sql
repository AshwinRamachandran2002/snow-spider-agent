WITH python_imports AS (          -- imports in *.py and *.ipynb
    SELECT
        REGEXP_SUBSTR(f.value::STRING,
                      'import\\s+([A-Za-z0-9_\\.]+)',
                      1, 1, 'e', 1) AS lib
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE (c."sample_path" ILIKE '%.py'
           OR c."sample_path" ILIKE '%.ipynb')
      AND f.value ILIKE '%import %'

    UNION ALL

    SELECT
        REGEXP_SUBSTR(f.value::STRING,
                      'from\\s+([A-Za-z0-9_\\.]+)\\s+import',
                      1, 1, 'e', 1) AS lib
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE (c."sample_path" ILIKE '%.py'
           OR c."sample_path" ILIKE '%.ipynb')
      AND f.value ILIKE 'from %import%'
),
r_imports AS (                   -- libraries loaded in *.r / *.R / *.Rmd
    SELECT
        REGEXP_SUBSTR(f.value::STRING,
                      '(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)',
                      1, 1, 'e', 2) AS lib
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE (c."sample_path" ILIKE '%.r'
           OR c."sample_path" ILIKE '%.R'
           OR c."sample_path" ILIKE '%.rmd'
           OR c."sample_path" ILIKE '%.Rmd')
      AND (f.value ILIKE 'library(%'
           OR f.value ILIKE 'require(%')
),
all_imports AS (
    SELECT lib FROM python_imports
    UNION ALL
    SELECT lib FROM r_imports
),
import_counts AS (
    SELECT
        lib AS library,
        COUNT(*) AS import_count
    FROM all_imports
    WHERE lib IS NOT NULL
    GROUP BY lib
)
SELECT library, import_count
FROM (
    SELECT
        library,
        import_count,
        ROW_NUMBER() OVER (ORDER BY import_count DESC NULLS LAST, library) AS rn
    FROM import_counts
)
WHERE rn = 2;