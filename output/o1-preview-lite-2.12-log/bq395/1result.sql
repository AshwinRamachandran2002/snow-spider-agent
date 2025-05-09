WITH State_Percentage_Change AS (
  SELECT
    t2015.State_Abbreviation,
    SAFE_DIVIDE(
      (t2018.Total_Unsheltered_2018 - t2015.Total_Unsheltered_2015),
      t2015.Total_Unsheltered_2015
    ) * 100 AS Percentage_Change
  FROM
    (
      SELECT
        SUBSTR(`CoC_Number`, 1, 2) AS State_Abbreviation,
        SUM(IFNULL(`Unsheltered_Homeless_Individuals`, 0)) AS Total_Unsheltered_2015
      FROM
        `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
      WHERE
        `Count_Year` = 2015
      GROUP BY
        State_Abbreviation
    ) AS t2015
  INNER JOIN
    (
      SELECT
        SUBSTR(`CoC_Number`, 1, 2) AS State_Abbreviation,
        SUM(IFNULL(`Unsheltered_Homeless_Individuals`, 0)) AS Total_Unsheltered_2018
      FROM
        `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
      WHERE
        `Count_Year` = 2018
      GROUP BY
        State_Abbreviation
    ) AS t2018
  ON
    t2015.State_Abbreviation = t2018.State_Abbreviation
),
National_Avg AS (
  SELECT
    SAFE_DIVIDE(
      (SUM_Curr - SUM_Prev),
      SUM_Prev
    ) * 100 AS National_Percentage_Change
  FROM
    (
      SELECT
        SUM(CASE WHEN `Count_Year` = 2015 THEN IFNULL(`Unsheltered_Homeless_Individuals`, 0) ELSE 0 END) AS SUM_Prev,
        SUM(CASE WHEN `Count_Year` = 2018 THEN IFNULL(`Unsheltered_Homeless_Individuals`, 0) ELSE 0 END) AS SUM_Curr
      FROM
        `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
      WHERE
        `Count_Year` IN (2015, 2018)
    )
)
SELECT
  State_Abbreviation
FROM
  State_Percentage_Change, National_Avg
ORDER BY
  ABS(Percentage_Change - National_Percentage_Change) ASC
LIMIT 5;