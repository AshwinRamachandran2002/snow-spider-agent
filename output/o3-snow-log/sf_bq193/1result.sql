/* 1.  Extract every non-empty, non-comment line from README.md files */
WITH readme_lines AS (
    SELECT
        f."repo_name",
        TRIM(s.value::STRING) AS line
    FROM  "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_FILES"     f
    JOIN  "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_CONTENTS"  c
          ON f."id" = c."id",
         LATERAL SPLIT_TO_TABLE(c."content", '\n')  s
    WHERE f."path" ILIKE '%README.md'
      AND TRIM(s.value::STRING) <> ''              -- non-empty
      AND TRIM(s.value::STRING) NOT ILIKE '#%'     -- skip markdown comments
      AND TRIM(s.value::STRING) NOT ILIKE '//%'    -- skip code comments
),

/* 2.  Map every (line, repo) pair to the repo’s individual languages */
line_repo_language AS (
    SELECT
        rl.line,
        rl."repo_name",
        /* handle language as either object{"name":..} or plain string */
        COALESCE(
            lang.value:"name"::STRING,
            lang.value::STRING
        ) AS language_name
    FROM readme_lines             rl
    JOIN "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"  l
         ON rl."repo_name" = l."repo_name",
         LATERAL FLATTEN(input => l."language")     lang
    WHERE COALESCE(
            lang.value:"name"::STRING,
            lang.value::STRING
          ) IS NOT NULL
),

/* 3.  Frequency of each cleaned line across *all* README files */
line_stats AS (
    SELECT
        line                    AS clean_line,
        COUNT(*)                AS line_frequency
    FROM readme_lines
    GROUP BY line
),

/* 4.  Aggregate distinct languages per line, sorted alphabetically */
line_langs AS (
    SELECT
        line,
        ARRAY_TO_STRING(
            ARRAY_SORT(
                ARRAY_AGG(DISTINCT language_name)
            ), ', '
        )                      AS languages
    FROM line_repo_language
    GROUP BY line
)

/* 5.  Final result */
SELECT
    ls.clean_line,
    ls.line_frequency,
    COALESCE(ll.languages, '')      AS languages
FROM line_stats   ls
LEFT JOIN line_langs ll
       ON ls.clean_line = ll.line
ORDER BY ls.line_frequency DESC NULLS LAST;