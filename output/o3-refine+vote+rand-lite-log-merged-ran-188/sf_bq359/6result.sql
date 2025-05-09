WITH lang_rank AS (
    SELECT
        l."repo_name",
        CASE 
            WHEN TYPEOF(f.value) = 'NUMBER' THEN f.key::STRING                      -- e.g. {"JavaScript": 12345}
            WHEN TYPEOF(f.value) = 'OBJECT' THEN f.value:"name"::STRING            -- e.g. {"name":"JavaScript","bytes":12345}
        END                                   AS "language_name",
        CASE 
            WHEN TYPEOF(f.value) = 'NUMBER' THEN f.value::NUMBER
            WHEN TYPEOF(f.value) = 'OBJECT' THEN f.value:"bytes"::NUMBER
        END                                   AS "bytes",
        ROW_NUMBER() OVER (
            PARTITION BY l."repo_name"
            ORDER BY 
                CASE 
                    WHEN TYPEOF(f.value) = 'NUMBER' THEN f.value::NUMBER
                    WHEN TYPEOF(f.value) = 'OBJECT' THEN f.value:"bytes"::NUMBER
                END DESC NULLS LAST
        )                                     AS rn
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(INPUT => l."language") f
    WHERE TYPEOF(f.value) IN ('NUMBER', 'OBJECT')
),
primary_js_repos AS (
    SELECT "repo_name"
    FROM   lang_rank
    WHERE  rn = 1
      AND  "language_name" = 'JavaScript'
),
commit_counts AS (
    SELECT
        "repo_name",
        COUNT(*) AS "commit_count"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS
    GROUP BY "repo_name"
)
SELECT
    cc."repo_name",
    cc."commit_count"
FROM commit_counts cc
JOIN primary_js_repos pj
  ON cc."repo_name" = pj."repo_name"
ORDER BY
    cc."commit_count" DESC NULLS LAST,
    cc."repo_name"
LIMIT 2;