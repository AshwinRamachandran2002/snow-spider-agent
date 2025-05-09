SELECT
    SUM(
        CASE
            WHEN LOWER(f."path") LIKE '%readme.md%'
             AND LOWER(c."content") LIKE '%copyright (c)%'
            THEN 1 ELSE 0
        END
    )                                                AS "numerator_readme_copyright",
    COUNT(*)                                         AS "denominator_all_files",
    ROUND(
        SUM(
            CASE
                WHEN LOWER(f."path") LIKE '%readme.md%'
                 AND LOWER(c."content") LIKE '%copyright (c)%'
                THEN 1 ELSE 0
            END
        )::FLOAT
        / NULLIF(COUNT(*), 0),
        4
    )                                                AS "proportion"
FROM  GITHUB_REPOS.GITHUB_REPOS.SAMPLE_FILES     AS f
JOIN  GITHUB_REPOS.GITHUB_REPOS.LANGUAGES        AS l
      ON l."repo_name" = f."repo_name"
LEFT JOIN GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS AS c
      ON c."id" = f."id"
WHERE LOWER(l."language") NOT LIKE '%python%';