WITH repo_langs AS (   -- languages list per repository
    SELECT
        l."repo_name",
        ARRAY_SORT(
            ARRAY_DISTINCT(
                ARRAY_AGG(f.value::string)
            )
        )                                AS langs
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(
             INPUT => CASE
                          WHEN TYPEOF(l."language") = 'OBJECT'
                               THEN OBJECT_KEYS(l."language")   -- object → keys
                          ELSE l."language"                     -- array  → itself
                      END
         ) f
    GROUP BY l."repo_name"
),
readme_lines AS (       -- all non‑empty, non‑comment lines from README.md
    SELECT
        c."sample_repo_name"           AS repo_name,
        TRIM(fl.value::string)         AS line
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS c,
         LATERAL FLATTEN(
             INPUT => SPLIT(c."content", '\n')
         ) fl
    WHERE LOWER(c."sample_path") LIKE '%readme.md'
      AND TRIM(fl.value::string) <> ''
      AND NOT REGEXP_LIKE(TRIM(fl.value::string), '^(#|//)')
)
SELECT
    rl.line,
    COUNT(DISTINCT rl.repo_name)       AS frequency,
    ARRAY_TO_STRING(                   -- comma‑separated, sorted languages
        ARRAY_SORT(
            ARRAY_AGG(DISTINCT lflt.value::string)
        ),
        ','
    )                                  AS languages
FROM readme_lines rl
LEFT JOIN repo_langs pl
       ON rl.repo_name = pl."repo_name"
CROSS JOIN LATERAL FLATTEN(            -- expand language arrays, keep nulls
        INPUT  => pl.langs,
        OUTER  => TRUE
     ) lflt
GROUP BY rl.line
ORDER BY frequency DESC NULLS LAST, rl.line;