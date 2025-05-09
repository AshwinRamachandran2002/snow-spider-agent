WITH exploded AS (
    SELECT
        l."repo_name",
        /* language name comes either from the object’s "name" field
           (array‑of‑objects form) or from the FLATTEN key (map form) */
        CASE
            WHEN TYPEOF(f.value) = 'OBJECT'
                 THEN f.value:"name"::STRING
            ELSE f.key::STRING
        END                                                    AS "language",
        /* byte count comes either from the object’s "bytes" field
           or directly from the FLATTEN value */
        CASE
            WHEN TYPEOF(f.value) = 'OBJECT'
                 THEN TRY_TO_NUMBER(f.value:"bytes"::STRING)
            ELSE TRY_TO_NUMBER(f.value::STRING)
        END                                                    AS "bytes"
    FROM GITHUB_REPOS.GITHUB_REPOS.LANGUAGES l,
         LATERAL FLATTEN(INPUT => l."language") f
),
primary_lang AS (   /* keep only the largest‑byte language per repo */
    SELECT
        "repo_name",
        "language",
        ROW_NUMBER() OVER (PARTITION BY "repo_name"
                           ORDER BY "bytes" DESC NULLS LAST) AS rn
    FROM exploded
    WHERE "bytes" IS NOT NULL
)
SELECT
    sc."repo_name",
    COUNT(*) AS "commit_count"
FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_COMMITS sc
JOIN primary_lang pl
  ON sc."repo_name" = pl."repo_name"
WHERE pl.rn = 1                    -- primary language only
  AND pl."language" = 'JavaScript' -- primary language = JavaScript
GROUP BY sc."repo_name"
ORDER BY "commit_count" DESC NULLS LAST, sc."repo_name"
LIMIT 2;