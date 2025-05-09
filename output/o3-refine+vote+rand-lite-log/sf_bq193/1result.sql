WITH readme_files AS (        -- grab README.md files (any case)
    SELECT  f."repo_name",
            c."content"
    FROM    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES   f
    JOIN    GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c
           ON c."id" = f."id"
    WHERE   LOWER(f."path") LIKE '%readme.md'
),
readme_lines AS (             -- split into lines, drop blanks & comments
    SELECT  rf."repo_name",
            TRIM(fl.value::string) AS line
    FROM    readme_files rf,
            LATERAL FLATTEN(INPUT => SPLIT(rf."content", '\n')) fl
    WHERE   TRIM(fl.value::string) <> ''
      AND   NOT REGEXP_LIKE( TRIM(fl.value::string), '^(#|//)' )
),
line_frequency AS (           -- frequency of each unique line
    SELECT  line,
            COUNT(*) AS freq
    FROM    readme_lines
    GROUP BY line
),
line_repo_language AS (       -- associate each line with each language in its repo
    SELECT  DISTINCT
            rl.line,
            LOWER(le.value:"name"::string) AS lang
    FROM    readme_lines rl
    JOIN    GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l
           ON rl."repo_name" = l."repo_name",
            LATERAL FLATTEN(INPUT => l."language") le
    WHERE   le.value:"name" IS NOT NULL
),
line_languages AS (           -- comma‑separated language list per line
    SELECT  line,
            LISTAGG(DISTINCT lang, ',') WITHIN GROUP (ORDER BY lang) AS languages
    FROM    line_repo_language
    GROUP BY line
)
SELECT  lf.line,
        COALESCE(ll.languages, '') AS languages,
        lf.freq
FROM    line_frequency lf
LEFT JOIN line_languages ll
       ON lf.line = ll.line
ORDER BY lf.freq DESC NULLS LAST,
         lf.line;