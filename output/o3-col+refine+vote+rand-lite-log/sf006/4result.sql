WITH snapshot_2020 AS (   -- entities active on 01-Mar-2020
    SELECT
        "STATE_ABBREVIATION",
        COUNT(*) AS "branches_20200301"
    FROM FINANCE__ECONOMICS.CYBERSYN."FINANCIAL_BRANCH_ENTITIES"
    WHERE "START_DATE" <= '2020-03-01'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2020-03-01' )
    GROUP BY "STATE_ABBREVIATION"
),
snapshot_2021 AS (   -- entities active on 31-Dec-2021
    SELECT
        "STATE_ABBREVIATION",
        COUNT(*) AS "branches_20211231"
    FROM FINANCE__ECONOMICS.CYBERSYN."FINANCIAL_BRANCH_ENTITIES"
    WHERE "START_DATE" <= '2021-12-31'
      AND ( "END_DATE" IS NULL OR "END_DATE" >= '2021-12-31' )
    GROUP BY "STATE_ABBREVIATION"
)

SELECT
    COALESCE(s21."STATE_ABBREVIATION", s20."STATE_ABBREVIATION")                 AS "STATE_ABBREVIATION",
    s20."branches_20200301",
    s21."branches_20211231",
    CASE
        WHEN s20."branches_20200301" IS NULL
          OR s20."branches_20200301" = 0          THEN NULL
        ELSE ROUND(
                 (s21."branches_20211231" - s20."branches_20200301")
                 / s20."branches_20200301" * 100 ,
                 2
             )
    END                                                                           AS "pct_change_2020_to_2021"
FROM snapshot_2020 s20
FULL OUTER JOIN snapshot_2021 s21
  ON s20."STATE_ABBREVIATION" = s21."STATE_ABBREVIATION"
ORDER BY "pct_change_2020_to_2021" DESC NULLS LAST;