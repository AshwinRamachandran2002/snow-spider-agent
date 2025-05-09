WITH readme_lines AS (   -- every non‑empty, non‑comment line from README.md files
    SELECT
        sf."repo_name",
        TRIM(fl.value::string)         AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     sf
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  sc
          ON sc."id" = sf."id"
         ,LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') ) fl
    WHERE LOWER(sf."path") LIKE '%readme.md'        -- README.md files
      AND TRIM(fl.value::string) <> ''              -- non‑empty
      AND NOT REGEXP_LIKE(TRIM(fl.value::string)    -- skip # … or // …
                      , '^(#|//)')
),
languages_flat AS (      -- one row per (repo, language)
    SELECT
        lg."repo_name",
        COALESCE(f.key::string, f.value::string) AS language
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES lg
         ,LATERAL FLATTEN( INPUT => lg."language") f
    WHERE COALESCE(f.key::string, f.value::string) IS NOT NULL
)
SELECT
    rl.line,
    COUNT(*)                                                   AS occurrence_count,
    LISTAGG(DISTINCT lf.language, ',') 
        WITHIN GROUP (ORDER BY lf.language)                    AS languages_used
FROM readme_lines   rl
LEFT JOIN languages_flat lf
       ON lf."repo_name" = rl."repo_name"
GROUP BY rl.line
ORDER BY occurrence_count DESC NULLS LAST, rl.line;