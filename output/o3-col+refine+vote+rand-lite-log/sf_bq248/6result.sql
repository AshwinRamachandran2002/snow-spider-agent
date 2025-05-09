WITH non_python_repos AS (  -- repositories that use no language whose name contains 'python'
    SELECT DISTINCT l1."repo_name"
    FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l1
    WHERE  l1."repo_name" NOT IN (
              SELECT DISTINCT l2."repo_name"
              FROM   GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l2,
                     LATERAL FLATTEN(input => l2."language") f2
              WHERE  LOWER(f2.value::STRING) LIKE '%python%'
           )
),
repo_files AS (            -- all files belonging to those repositories
    SELECT sf."repo_name",
           sf."path"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES sf
    WHERE  sf."repo_name" IN (SELECT "repo_name" FROM non_python_repos)
),
files_with_content AS (    -- attach file contents when available
    SELECT rf."repo_name",
           rf."path",
           sc."content"
    FROM   repo_files rf
    LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
           ON rf."repo_name" = sc."sample_repo_name"
          AND rf."path"      = sc."sample_path"
)
SELECT
    ROUND(
        COUNT_IF(
            LOWER("path") LIKE '%readme.md%'      -- file path includes 'readme.md'
            AND LOWER("content") LIKE '%copyright (c)%'  -- content has 'copyright (c)'
        ) :: FLOAT
        /
        NULLIF(COUNT(*), 0)   -- total files from non-python repositories
    , 4
) AS "proportion_readme_md_with_copyright_c"
FROM files_with_content;