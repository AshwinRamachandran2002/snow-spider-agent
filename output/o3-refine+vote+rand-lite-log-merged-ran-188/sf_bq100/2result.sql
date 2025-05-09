WITH seq AS (                                   -- generate 1 … 1000 for “nth” occurrence
    SELECT SEQ4() + 1 AS occ
    FROM TABLE(GENERATOR(ROWCOUNT => 1000))
),

blocks AS (                                     -- every import ( ... ) block
    SELECT  c."id",
            REGEXP_SUBSTR(
                c."content",
                'import\\s*\\(([^)]*)\\)',      -- text inside import(...)
                1,                              -- start position
                seq.occ,                        -- nth occurrence (must be ≥1)
                'es',                           -- e = extract subgroup, s = dot‑matches‑newline
                1                               -- subgroup to return
            ) AS block_txt
    FROM   GITHUB_REPOS.GITHUB_REPOS."SAMPLE_CONTENTS"  AS c
    CROSS  JOIN seq
    WHERE  REGEXP_SUBSTR(
                c."content",
                'import\\s*\\(([^)]*)\\)',
                1,
                seq.occ,
                'es',
                1
           ) IS NOT NULL
),

lines AS (                                      -- split block into individual lines
    SELECT  b."id",
            TRIM(st.VALUE) AS line
    FROM    blocks b,
            LATERAL SPLIT_TO_TABLE(b.block_txt, '\n') st
),

packages AS (                                   -- extract package names within quotes
    SELECT  REGEXP_SUBSTR(line, '"([^"]+)"', 1, 1, 'e', 1) AS package
    FROM    lines
    WHERE   REGEXP_SUBSTR(line, '"([^"]+)"', 1, 1, 'e', 1) IS NOT NULL
),

pkg_counts AS (                                 -- count frequency
    SELECT  package,
            COUNT(*) AS freq
    FROM    packages
    GROUP BY package
)

SELECT  package   AS "PACKAGE",
        freq      AS "FREQUENCY"
FROM    pkg_counts
ORDER BY freq DESC NULLS LAST, package
LIMIT 10;