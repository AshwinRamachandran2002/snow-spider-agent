WITH readme_lines AS (   -- non‑empty & non‑comment lines coming from README.md files
    SELECT
        sf."repo_name"                                                  AS repo_name ,
        TRIM( ln.value::string )                                        AS line
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_FILES"    AS sf
    JOIN GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS" AS sc
          ON sf."id" = sc."id"
    CROSS JOIN LATERAL FLATTEN( INPUT => SPLIT( sc."content" , '\n' ) ) AS ln
    WHERE LOWER( sf."path" ) LIKE '%readme.md'                 -- keep README files
      AND TRIM( ln.value::string ) <> ''                       -- omit empty lines
      AND NOT REGEXP_LIKE( TRIM( ln.value::string ) , '^(#|//)')  -- exclude comments
),
repo_langs AS (   -- extract language names per repository
    SELECT
        lg."repo_name"                                           AS repo_name ,
        fl.value:"name"::string                                  AS language
    FROM GITHUB_REPOS.GITHUB_REPOS."LANGUAGES" AS lg
    CROSS JOIN LATERAL FLATTEN( INPUT => lg."language" ) AS fl
    WHERE fl.value:"name" IS NOT NULL
)
SELECT
    rl.line                                                                 AS line ,
    COUNT(*)                                                                AS frequency ,
    LISTAGG( DISTINCT rlg.language , ', ' )
         WITHIN GROUP ( ORDER BY rlg.language )                             AS languages
FROM readme_lines rl
LEFT JOIN repo_langs rlg
       ON rl.repo_name = rlg.repo_name
GROUP BY rl.line
ORDER BY frequency DESC NULLS LAST , rl.line;