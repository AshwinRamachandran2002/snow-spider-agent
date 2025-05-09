WITH downloads AS (                           -- total downloads per project
    SELECT 
        UPPER("project") AS "PKG_NAME",
        COUNT(*)         AS "DL_CNT"
    FROM PYPI.PYPI.FILE_DOWNLOADS
    GROUP BY UPPER("project")
),                                                              
latest_meta AS (                           -- most‑recent metadata row per package
    SELECT
        UPPER("name")                       AS "PKG_NAME",
        COALESCE("project_urls"::string,'') AS "PURL_STR",
        COALESCE("home_page"::string,'')    AS "HOME_STR",
        ROW_NUMBER() OVER (PARTITION BY UPPER("name") 
                           ORDER BY "upload_time" DESC) AS rn
    FROM PYPI.PYPI.DISTRIBUTION_METADATA
),                          
meta_clean AS (                            -- extract & clean first GitHub URL
    SELECT
        lm."PKG_NAME",
        REGEXP_REPLACE(                                            -- trim trailing '/'
            REGEXP_REPLACE(                                        -- keep owner/repo only
                REGEXP_REPLACE(                                    -- drop ".git"
                    REGEXP_SUBSTR(                                 -- first GitHub match
                        lm."PURL_STR" || ' ' || lm."HOME_STR",
                        'https?://github\\.com/[^/]+/[^/\\s"]+',
                        1, 1, 'i'
                    ),
                    '\\.git$','',1,0,'i'
                ),
                '(https?://github\\.com/[^/]+/[^/]+)(/.*)?',
                '\\1',1,0,'i'
            ),
            '/$',''
        ) AS "REPO_URL"
    FROM latest_meta lm
    WHERE lm.rn = 1
),
final AS (                                  -- join with download counts
    SELECT 
        d."PKG_NAME",
        d."DL_CNT",
        m."REPO_URL"
    FROM downloads d
    JOIN meta_clean m
      ON m."PKG_NAME" = d."PKG_NAME"
    WHERE m."REPO_URL" IS NOT NULL
)
SELECT "REPO_URL"
FROM final
ORDER BY "DL_CNT" DESC NULLS LAST, "PKG_NAME"
LIMIT 3;