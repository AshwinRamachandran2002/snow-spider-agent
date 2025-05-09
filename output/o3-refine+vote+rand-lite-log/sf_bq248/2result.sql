WITH no_python_repos AS (          -- repositories that do NOT mention “python” in their language list
    SELECT DISTINCT f."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES      AS f
    LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.LANGUAGES    AS l
           ON f."repo_name" = l."repo_name"
    WHERE l."repo_name" IS NULL                                   -- no language info at all
          OR LOWER(TO_VARCHAR(l."language")) NOT LIKE '%python%'  -- language info present but no “python”
),
readme_files AS (              -- README.md‑like files inside the no‑python repositories
    SELECT f."id",
           f."repo_name"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES AS f
    JOIN no_python_repos                       AS n
         ON n."repo_name" = f."repo_name"
    WHERE LOWER(f."path") LIKE '%readme.md%'               -- path contains “readme.md”
),
readme_with_content AS (       -- attach file contents
    SELECT rf."id",
           rf."repo_name",
           c."content"
    FROM readme_files                                   AS rf
    JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS      AS c
         ON c."id" = rf."id"
        AND c."sample_repo_name" = rf."repo_name"
)
SELECT
    ROUND(
        SUM(CASE WHEN LOWER("content") LIKE '%copyright (c)%' THEN 1 ELSE 0 END)::FLOAT
        / NULLIF(COUNT(*), 0), 
        4
    ) AS proportion
FROM readme_with_content;