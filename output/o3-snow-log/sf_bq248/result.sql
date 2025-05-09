WITH no_python_repos AS (
    /* repositories whose language list does NOT mention “python” */
    SELECT DISTINCT f."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES        AS f
    LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES      AS l
           ON f."repo_name" = l."repo_name"
    WHERE l."repo_name" IS NULL                 /* repo has no language row   */
          OR LOWER(l."language"::STRING) NOT LIKE '%python%'   /* or no python */
), 
readme_files AS (
    /* every README.md file that belongs to those repos */
    SELECT sf."id"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS sf
    JOIN   no_python_repos                        AS npr
           ON sf."repo_name" = npr."repo_name"
    WHERE  LOWER(sf."path") LIKE '%readme.md%'
),
readme_with_copyright AS (
    /* README.md files whose content contains "Copyright (c)" */
    SELECT rf."id"
    FROM   readme_files                          AS rf
    JOIN   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS sc
           ON rf."id" = sc."id"
    WHERE  LOWER(sc."content") LIKE '%copyright (c)%'
)
SELECT 
    /* proportion = README.md files containing copyright /
                    all README.md files in non-python repos */
    (COUNT(*)::FLOAT) 
    / NULLIF((SELECT COUNT(*) FROM readme_files), 0)  AS "proportion"
FROM readme_with_copyright;