WITH lines AS (   -- every distinct, non-empty, non-comment line per repository
    SELECT DISTINCT
           c."sample_repo_name"                          AS repo,
           TRIM(f.value)                                 AS line
    FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  c,
          LATERAL SPLIT_TO_TABLE(c."content", '\n') f
    WHERE c."sample_path" ILIKE '%README.md'
      AND TRIM(f.value) <> ''
      AND TRIM(f.value) NOT RLIKE '^(#|//)'
),
repo_langs AS (    -- comma-separated language list for each repository
    SELECT
        "repo_name"                                     AS repo,
        LISTAGG(DISTINCT CAST("language" AS STRING), ',')
            WITHIN GROUP (ORDER BY CAST("language" AS STRING))  AS languages
    FROM  GITHUB_REPOS.GITHUB_REPOS.LANGUAGES
    GROUP BY "repo_name"
),
line_repo_lang AS (   -- combine lines with their repository language lists
    SELECT
        l.line,
        l.repo,
        rl.languages
    FROM  lines      l
    LEFT JOIN repo_langs rl
           ON l.repo = rl.repo
)
SELECT
    line,
    COUNT(DISTINCT repo)                                                        AS repo_occurrences,
    LISTAGG(DISTINCT languages, ',') WITHIN GROUP (ORDER BY languages)          AS languages
FROM line_repo_lang
GROUP BY line
ORDER BY repo_occurrences DESC NULLS LAST;