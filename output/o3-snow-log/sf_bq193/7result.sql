WITH readme_lines AS (                       /* every raw line from README.md files */
    SELECT
        sc."sample_repo_name"                       AS repo,
        TRIM(f.value::STRING)                       AS line
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS  sc,
           LATERAL FLATTEN( INPUT => SPLIT(sc."content", '\n') ) f
    WHERE  sc."sample_path" ILIKE '%README.md'
),
clean_lines AS (                           /* keep only meaningful, non-comment lines */
    SELECT DISTINCT
           repo,
           line
    FROM   readme_lines
    WHERE  line <> ''
      AND  NOT line LIKE '#%'               /* skip Markdown headings/comments */
      AND  NOT line LIKE '//%'              /* skip code-style comments       */
),
repo_languages AS (                        /* explode JSON language arrays to rows */
    SELECT
        l."repo_name"                             AS repo,
        fl.value:"name"::STRING                   AS language
    FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
           LATERAL FLATTEN( INPUT => l."language") fl
),
line_freq AS (                             /* how many repos contain each line */
    SELECT
        line,
        COUNT(DISTINCT repo)                      AS repo_cnt
    FROM   clean_lines
    GROUP BY line
),
line_langs AS (                            /* collect languages per line */
    SELECT
        cl.line,
        ARRAY_AGG(DISTINCT rl.language)           AS langs
    FROM   clean_lines        cl
    LEFT  JOIN repo_languages rl  ON rl.repo = cl.repo
    GROUP BY cl.line
)
SELECT
    lf.line,
    lf.repo_cnt,
    ARRAY_TO_STRING(ARRAY_SORT(ll.langs), ',')    AS language_list
FROM   line_freq  lf
JOIN   line_langs ll  ON ll.line = lf.line
ORDER BY lf.repo_cnt DESC NULLS LAST;