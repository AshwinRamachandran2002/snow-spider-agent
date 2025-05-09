WITH contents AS (                               -- keep only files that contain “import (”
    SELECT "content"
    FROM GITHUB_REPOS.GITHUB_REPOS.SAMPLE_CONTENTS
    WHERE "content" ILIKE '%import (%'
),
occurrences AS (                                 -- generate 50 possible occurrences per file
    SELECT
        c."content",
        seq4() AS occ
    FROM contents c,
         TABLE(GENERATOR(ROWCOUNT => 50))
),
blocks AS (                                      -- capture text inside each import‑block ()
    SELECT
        REGEXP_SUBSTR(
            "content",
            'import\\s*\\(([\\s\\S]*?)\\)',       -- [\\s\\S] matches newlines, non‑greedy
            1,
            occ + 1,
            'e',                                 -- return capture group 1
            1
        ) AS block
    FROM occurrences
),
packages AS (                                    -- split block lines, extract package names
    SELECT
        REGEXP_REPLACE(
            REGEXP_SUBSTR(line.VALUE, '"([^"]+)"', 1, 1, 'e', 1),
            '"',
            ''
        ) AS package_name
    FROM blocks b,
         TABLE(SPLIT_TO_TABLE(b.block, '\n')) line
    WHERE b.block IS NOT NULL
      AND REGEXP_SUBSTR(line.VALUE, '"([^"]+)"', 1, 1, 'e', 1) IS NOT NULL
)
SELECT
    package_name,
    COUNT(*) AS frequency
FROM packages
WHERE package_name IS NOT NULL
GROUP BY package_name
ORDER BY frequency DESC NULLS LAST, package_name
LIMIT 10;