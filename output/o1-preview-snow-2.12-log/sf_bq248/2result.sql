SELECT
    (SELECT COUNT(*)::FLOAT
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
    WHERE LOWER(sc."sample_path") LIKE '%readme.md%'
      AND LOWER(sc."content") LIKE '%copyright (c)%'
      AND sc."sample_repo_name" IN (
          SELECT DISTINCT t."repo_name"
          FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES t
          WHERE t."repo_name" NOT IN (
              SELECT DISTINCT t2."repo_name"
              FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES t2,
                   LATERAL FLATTEN(input => t2."language") f
              WHERE LOWER(f.value::STRING) LIKE '%python%'
          )
      )
    ) / 
    (SELECT COUNT(*)
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS sc
    WHERE sc."sample_repo_name" IN (
        SELECT DISTINCT t."repo_name"
        FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES t
        WHERE t."repo_name" NOT IN (
            SELECT DISTINCT t2."repo_name"
            FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES t2,
                 LATERAL FLATTEN(input => t2."language") f
            WHERE LOWER(f.value::STRING) LIKE '%python%'
        )
    )
    ) AS "Proportion";