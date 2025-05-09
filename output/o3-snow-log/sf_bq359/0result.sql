WITH "LANG_FLAT" AS (  -- explode each language entry and normalise fields
    SELECT
        l."repo_name",
        LOWER(
            COALESCE(
                f.value:"name"::string,      -- array element object form
                f.key::string,               -- object form key
                f.value::string              -- simple scalar
            )
        )                    AS "language",
        NVL(                 -- try to capture the byte-count if present
            TRY_TO_NUMBER(f.value:"bytes"::string),
            TRY_TO_NUMBER(f.value::string)
        )                    AS "bytes"
    FROM  "GITHUB_REPOS"."GITHUB_REPOS"."LANGUAGES"  AS l,
          LATERAL FLATTEN ( INPUT => l."language" )  AS f
), 
"LANG_RANK" AS (         -- rank languages (largest byte-count = primary)
    SELECT
        "repo_name",
        "language",
        COALESCE("bytes", 0)                            AS "bytes",
        RANK() OVER (PARTITION BY "repo_name"
                     ORDER BY COALESCE("bytes",0) DESC) AS rnk
    FROM  "LANG_FLAT"
), 
"JS_PRIMARY_REPOS" AS (  -- repos whose primary language is JavaScript
    SELECT DISTINCT "repo_name"
    FROM   "LANG_RANK"
    WHERE  rnk = 1
      AND  "language" = 'javascript'
), 
"COMMIT_COUNTS" AS (     -- count commits for those repositories
    SELECT
        c."repo_name",
        COUNT(*) AS commit_count
    FROM   "GITHUB_REPOS"."GITHUB_REPOS"."SAMPLE_COMMITS" AS c
    JOIN   "JS_PRIMARY_REPOS"                              AS j
      ON   c."repo_name" = j."repo_name"
    GROUP BY c."repo_name"
)
SELECT
    "repo_name",
    commit_count
FROM   "COMMIT_COUNTS"
ORDER  BY commit_count DESC NULLS LAST
LIMIT 2;