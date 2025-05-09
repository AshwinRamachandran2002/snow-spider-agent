WITH import_blocks AS (  -- grab every “import ( ... )” block from files that contain at least one
    SELECT
        REGEXP_SUBSTR_ALL("content",
                          'import[[:space:]]*\\([\\s\\S]*?\\)',
                          1,           -- start position
                          1,           -- 1st occurrence (all returned because *_ALL)
                          's'          -- allow “.” to span new-lines
                         )                AS "blocks"
    FROM   GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE  "content" ILIKE '%import (%'
),
flatten_blocks AS (      -- explode the array of blocks
    SELECT  VALUE::STRING AS "block"
    FROM    import_blocks,
            LATERAL FLATTEN(INPUT => "blocks")
),
quoted_pkgs AS (         -- inside every block pull out each quoted package string
    SELECT
        REGEXP_SUBSTR_ALL("block", '"[^"]+"') AS "pkg_arr"
    FROM   flatten_blocks
),
flatten_pkgs AS (        -- explode arrays and strip the quotes
    SELECT  TRIM(REPLACE(VALUE::STRING, '"', '')) AS "package"
    FROM    quoted_pkgs,
            LATERAL FLATTEN(INPUT => "pkg_arr")
    WHERE   VALUE IS NOT NULL
),
pkg_freq AS (            -- count how often each package occurs
    SELECT  "package",
            COUNT(*) AS "freq"
    FROM    flatten_pkgs
    WHERE   "package" <> ''
    GROUP BY "package"
)
SELECT  "package",
        "freq"
FROM    pkg_freq
ORDER BY "freq" DESC NULLS LAST
LIMIT 10;