/*  Return the CPC-filtered U.S. patent that                              *
 *  – cites at least one patent published ≤1 yr before its app date       *
 *  – is cited at least once ≤1 yr after its app date                     *
 *  – count forward citations occurring ≤3 yrs after its app date         *
 *  Ordered by number of such backward citations (desc), top record only  */

WITH application_dates AS (          -- earliest valid U.S. application date
    SELECT
        "patent_id",
        MIN(app_dt) AS app_date
    FROM (
        SELECT
            "patent_id",
            TRY_TO_DATE("date", 'YYYY-MM-DD') AS app_dt
        FROM PATENTSVIEW.PATENTSVIEW.APPLICATION
        WHERE "country" = 'US'
    ) t
    WHERE app_dt IS NOT NULL
    GROUP BY "patent_id"
),

/* ---- backward citations ≤1 yr before the focal patent’s app date ---- */
backward_1yr AS (
    SELECT
        uc."patent_id"           AS patent_id,
        COUNT(*)                 AS backward_cnt_1yr
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN application_dates ad
          ON ad."patent_id" = uc."patent_id"
    JOIN (
        SELECT
            "id"                                         AS cited_id,
            TRY_TO_DATE("date", 'YYYY-MM-DD') AS pub_dt
        FROM PATENTSVIEW.PATENTSVIEW.PATENT
        WHERE TRY_TO_DATE("date", 'YYYY-MM-DD') IS NOT NULL
          AND "country" = 'US'
    ) cited
          ON cited.cited_id = uc."citation_id"
    WHERE cited.pub_dt BETWEEN DATEADD(year, -1, ad.app_date) AND ad.app_date
    GROUP BY uc."patent_id"
),

/* ---- forward citations ≤3 yrs after focal patent’s app date --------- */
forward_3yr AS (
    SELECT
        uc."citation_id"         AS patent_id,          -- focal patent
        COUNT(*)                 AS forward_cnt_3yr
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN application_dates cited
          ON cited."patent_id" = uc."citation_id"
    JOIN application_dates citing
          ON citing."patent_id" = uc."patent_id"
    WHERE citing.app_date BETWEEN cited.app_date
                              AND DATEADD(year, 3, cited.app_date)
    GROUP BY uc."citation_id"
),

/* ---- ensure ≥1 forward citation ≤1 yr after app date ---------------- */
forward_1yr AS (
    SELECT
        uc."citation_id"         AS patent_id
    FROM PATENTSVIEW.PATENTSVIEW.USPATENTCITATION uc
    JOIN application_dates cited
          ON cited."patent_id" = uc."citation_id"
    JOIN application_dates citing
          ON citing."patent_id" = uc."patent_id"
    WHERE citing.app_date BETWEEN cited.app_date
                              AND DATEADD(year, 1, cited.app_date)
    GROUP BY uc."citation_id"
)

/* ----------------------------- final selection ----------------------- */
SELECT
    ad."patent_id",
    ad.app_date,
    b.backward_cnt_1yr,
    f3.forward_cnt_3yr
FROM application_dates                    ad
JOIN PATENTSVIEW.PATENTSVIEW.CPC_CURRENT  cc
     ON cc."patent_id" = ad."patent_id"
    AND cc."group_id" IN ('C08K', 'C08L')      -- target CPC groups
JOIN backward_1yr                            b  ON b.patent_id = ad."patent_id"
JOIN forward_1yr                             f1 ON f1.patent_id = ad."patent_id"
JOIN forward_3yr                             f3 ON f3.patent_id = ad."patent_id"
ORDER BY b.backward_cnt_1yr DESC NULLS LAST
LIMIT 1;