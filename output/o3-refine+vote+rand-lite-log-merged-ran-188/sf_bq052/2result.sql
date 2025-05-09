WITH patents_app AS (   -- 1) earliest (cleaned) application date for every patent
    SELECT
        "patent_id",
        MIN(
            TO_DATE(
                IFF(        -- replace day = '00' with '01' so Snowflake can cast
                    LENGTH("date") = 10
                    AND SUBSTR("date",9,2) = '00',
                    CONCAT(SUBSTR("date",1,8), '01'),
                    "date"
                ),
                'YYYY-MM-DD'
            )
        ) AS app_date
    FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
    GROUP BY "patent_id"
    HAVING app_date IS NOT NULL            -- keep only successfully‑parsed dates
),
cpc_filtered AS (       -- 2) patents in requested CPC classes
    SELECT DISTINCT
        "patent_id"
    FROM PATENTSVIEW.PATENTSVIEW.CPC_CURRENT
    WHERE  "subsection_id" = 'C05'      -- fertilisers
       OR  "group_id"     = 'A01G'      -- horticulture
),
backward_counts AS (    -- 3) citations MADE BY the current patent
    SELECT
        uc."patent_id"                    AS current_patent_id,
        COUNT(DISTINCT uc."citation_id")  AS backward_citations_1m
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN patents_app  p_cur   ON uc."patent_id"   = p_cur."patent_id"
    JOIN patents_app  p_cited ON uc."citation_id" = p_cited."patent_id"
    WHERE p_cited.app_date >= DATEADD(day,-30,p_cur.app_date)
      AND p_cited.app_date <  p_cur.app_date
    GROUP BY uc."patent_id"
),
forward_counts AS (     -- 4) citations RECEIVED BY the current patent
    SELECT
        uc."citation_id"                  AS current_patent_id,
        COUNT(DISTINCT uc."patent_id")    AS forward_citations_1m
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN patents_app p_cur    ON uc."citation_id" = p_cur."patent_id"
    JOIN patents_app p_citing ON uc."patent_id"   = p_citing."patent_id"
    WHERE p_citing.app_date >  p_cur.app_date
      AND p_citing.app_date <= DATEADD(day,30,p_cur.app_date)
    GROUP BY uc."citation_id"
)
SELECT
    p_cur."patent_id"                                  AS patent_id,
    pat."title",
    p_cur.app_date                                     AS application_date,
    COALESCE(b.backward_citations_1m,0) AS backward_citations_1m,
    COALESCE(f.forward_citations_1m ,0) AS forward_citations_1m,
    pat."abstract"
FROM patents_app                    p_cur
JOIN cpc_filtered                   cf  ON p_cur."patent_id" = cf."patent_id"
JOIN PATENTSVIEW.PATENTSVIEW.PATENT pat ON p_cur."patent_id" = pat."id"
LEFT JOIN backward_counts           b   ON p_cur."patent_id" = b.current_patent_id
LEFT JOIN forward_counts            f   ON p_cur."patent_id" = f.current_patent_id
WHERE COALESCE(b.backward_citations_1m,0) + COALESCE(f.forward_citations_1m,0) > 0
ORDER BY p_cur.app_date ASC, p_cur."patent_id" ASC;