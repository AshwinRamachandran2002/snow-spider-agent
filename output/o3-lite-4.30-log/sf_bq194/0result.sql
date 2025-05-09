WITH python_imports AS (
    SELECT
        LOWER(REGEXP_SUBSTR(f.value::STRING,
                            'import\\s+([A-Za-z0-9_\\.]+)', 1, 1, 'e', 1)) AS lib
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE c."sample_path" ILIKE '%.py'
      AND f.value ILIKE 'import %'
      AND f.value NOT ILIKE 'from % import%'          -- exclude "from x import y"
),
r_imports AS (
    SELECT
        LOWER(REGEXP_SUBSTR(f.value::STRING,
                            '(library|require)\\s*\\(\\s*([A-Za-z0-9_\\.]+)', 1, 1, 'e', 2)) AS lib
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE LOWER(c."sample_path") LIKE '%.r%'          -- .r, .R, .rmd, .Rmd
      AND (f.value ILIKE 'library(%' OR f.value ILIKE 'require(%')
),
ipynb_imports AS (
    SELECT
        LOWER(REGEXP_SUBSTR(f.value::STRING,
                            '"import\\s+([A-Za-z0-9_\\.]+)"', 1, 1, 'e', 1)) AS lib
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(INPUT => SPLIT(c."content", '\n')) f
    WHERE c."sample_path" ILIKE '%.ipynb'
      AND f.value ILIKE '%"import %'
),
all_imports AS (
    SELECT lib FROM python_imports
    UNION ALL
    SELECT lib FROM r_imports
    UNION ALL
    SELECT lib FROM ipynb_imports
)
SELECT
    library,
    import_count
FROM (
    SELECT
        lib AS library,
        COUNT(*) AS import_count,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC NULLS LAST, lib) AS rn
    FROM all_imports
    WHERE lib IS NOT NULL
    GROUP BY lib
)
WHERE rn = 2;