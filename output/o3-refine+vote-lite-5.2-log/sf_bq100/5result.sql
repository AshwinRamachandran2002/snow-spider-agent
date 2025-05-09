WITH seq AS (                          -- helper sequence 1 … 1000
    SELECT SEQ4() + 1 AS "occ"
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))
),
import_blocks AS (                     -- every “import ( … )” block
    SELECT
        REGEXP_SUBSTR(
            c."content",
            'import\\s*\\([\\s\\S]*?\\)',   -- non‑greedy block match
            1,                              -- start position
            s."occ"                         -- N‑th occurrence (>=1)
        ) AS "block"
    FROM GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS" c
    CROSS JOIN seq s
    WHERE REGEXP_SUBSTR(
              c."content",
              'import\\s*\\([\\s\\S]*?\\)',
              1,
              s."occ"
          ) IS NOT NULL                    -- keep only found blocks
),
import_lines AS (                         -- split each block into lines
    SELECT
        TRIM(fl."VALUE"::STRING) AS "line"
    FROM import_blocks b,
         LATERAL FLATTEN(INPUT => SPLIT(b."block", '\n')) fl
),
packages AS (                             -- extract quoted package paths
    SELECT
        REGEXP_SUBSTR(
            "line",
            '"([^"]+)"',                  -- first text inside quotes
            1, 1, 'e', 1
        ) AS "package"
    FROM import_lines
)
SELECT
    "package",
    COUNT(*) AS "frequency"
FROM packages
WHERE "package" IS NOT NULL
GROUP BY "package"
ORDER BY "frequency" DESC NULLS LAST, "package"
LIMIT 10;