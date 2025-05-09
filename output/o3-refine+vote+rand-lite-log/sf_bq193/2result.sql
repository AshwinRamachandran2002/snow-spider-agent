WITH readme_files AS (          -- 1. all README.md blobs
    SELECT
        "repo_name",
        "id"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES
    WHERE LOWER("path") LIKE '%readme.md'
),

readme_lines AS (               -- 2. individual, filtered lines
    SELECT
        rf."repo_name",
        TRIM(fl.value::string) AS "line"
    FROM readme_files rf
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
      ON rf."id" = sc."id"
    , LATERAL FLATTEN(input => SPLIT(sc."content", '\n')) fl
    WHERE TRIM(fl.value::string) <> ''                       -- non‑empty
      AND NOT REGEXP_LIKE(TRIM(fl.value::string), '^(#|//)') -- not a comment
),

repo_languages AS (              -- 3. language names per repo
    SELECT
        l."repo_name",
        f.key::string AS "language"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l
         , LATERAL FLATTEN(input => l."language") f
    WHERE TYPEOF(l."language") = 'OBJECT'   -- skip empty arrays like []
      AND f.key IS NOT NULL                 -- keep only object keys (= languages)
)

-- 4. aggregate result
SELECT
    rl."line",
    COUNT(*) AS "frequency",
    LISTAGG(DISTINCT rl_lang."language", ',') 
        WITHIN GROUP (ORDER BY rl_lang."language") AS "languages"
FROM readme_lines rl
LEFT JOIN repo_languages rl_lang
       ON rl."repo_name" = rl_lang."repo_name"
GROUP BY rl."line"
ORDER BY "frequency" DESC NULLS LAST, rl."line";