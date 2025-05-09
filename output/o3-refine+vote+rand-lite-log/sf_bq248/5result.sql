WITH python_repos AS (   -- repos that mention any language containing "python"
    SELECT DISTINCT l."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(input => l."language") f
    WHERE LOWER(COALESCE(f.key::string, f.value::string)) LIKE '%python%'
),
readme_files AS (        -- README.md files in repos that do NOT use Python
    SELECT sf."repo_name",
           sf."id"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES  sf
    WHERE sf."repo_name" NOT IN (SELECT "repo_name" FROM python_repos)
      AND LOWER(sf."path") LIKE '%readme.md%'
),
counts AS (              -- tally totals and those containing "Copyright (c)"
    SELECT
        COUNT(*) AS total_readme_files,
        SUM(CASE WHEN LOWER(sc."content") LIKE '%copyright (c)%'
                 THEN 1 ELSE 0 END) AS copyright_files
    FROM readme_files rf
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
      ON sc."id" = rf."id"
)
SELECT
    copyright_files::FLOAT
    / NULLIF(total_readme_files,0) AS proportion
FROM counts;