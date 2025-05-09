WITH readme_lines AS (
    /* 1. Split every README.md into individual, trimmed lines,
          discarding blank and comment lines                                       */
    SELECT
        f."repo_name"                                      AS repo_name,
        TRIM(line.value::STRING)                           AS line_clean
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     f
    JOIN  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c
          ON f."id" = c."id",
          LATERAL FLATTEN(input => SPLIT(c."content", '\n')) line
    WHERE f."path" ILIKE '%README.md'
      AND TRIM(line.value::STRING) <> ''                  -- non-empty
      AND TRIM(line.value::STRING) NOT ILIKE '#%'         -- skip “# …”
      AND TRIM(line.value::STRING) NOT ILIKE '//%'        -- skip “// …”
),
repo_languages AS (
    /* 2. Expand language arrays into one row per language per repo                */
    SELECT
        l."repo_name"                        AS repo_name,
        lang.value:"name"::STRING            AS language
    FROM  GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
          LATERAL FLATTEN(input => l."language") lang
)
SELECT
    rl.line_clean,
    COUNT(DISTINCT rl.repo_name)                                        AS repo_count,
    LISTAGG(DISTINCT rlang.language, ',')
        WITHIN GROUP (ORDER BY rlang.language)                          AS languages
FROM       readme_lines  rl
LEFT JOIN  repo_languages rlang
       ON  rl.repo_name = rlang.repo_name
GROUP BY   rl.line_clean
ORDER BY   repo_count DESC NULLS LAST;