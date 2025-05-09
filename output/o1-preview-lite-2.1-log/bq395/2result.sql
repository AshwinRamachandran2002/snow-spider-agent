SELECT
  s.State_Abbreviation
FROM (
  SELECT
    s.State_Abbreviation,
    s.Percentage_Change,
    n.National_Percentage_Change,
    ABS(s.Percentage_Change - n.National_Percentage_Change) AS Difference_From_National
  FROM (
    SELECT
      SUBSTR(`CoC_Number`, 1, 2) AS State_Abbreviation,
      SAFE_MULTIPLY(
        SAFE_DIVIDE(
          SUM(CASE WHEN `Count_Year` = 2018 THEN IFNULL(`Unsheltered_Homeless_Individuals`, 0) ELSE 0 END) -
          SUM(CASE WHEN `Count_Year` = 2015 THEN IFNULL(`Unsheltered_Homeless_Individuals`, 0) ELSE 0 END),
          NULLIF(SUM(CASE WHEN `Count_Year` = 2015 THEN IFNULL(`Unsheltered_Homeless_Individuals`, 0) ELSE 0 END), 0)
        ),
        100
      ) AS Percentage_Change
    FROM
      `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
    WHERE
      `Count_Year` IN (2015, 2018)
    GROUP BY
      State_Abbreviation
    HAVING
      SUM(CASE WHEN `Count_Year` = 2015 THEN IFNULL(`Unsheltered_Homeless_Individuals`, 0) ELSE 0 END) > 0
  ) AS s
  CROSS JOIN (
    SELECT
      SAFE_MULTIPLY(
        SAFE_DIVIDE(
          SUM(CASE WHEN `Count_Year` = 2018 THEN IFNULL(`Unsheltered_Homeless_Individuals`, 0) ELSE 0 END) -
          SUM(CASE WHEN `Count_Year` = 2015 THEN IFNULL(`Unsheltered_Homeless_Individuals`, 0) ELSE 0 END),
          NULLIF(SUM(CASE WHEN `Count_Year` = 2015 THEN IFNULL(`Unsheltered_Homeless_Individuals`, 0) ELSE 0 END), 0)
        ),
        100
      ) AS National_Percentage_Change
    FROM
      `bigquery-public-data.sdoh_hud_pit_homelessness.hud_pit_by_coc`
    WHERE
      `Count_Year` IN (2015, 2018)
  ) AS n
) AS s
ORDER BY
  Difference_From_National ASC
LIMIT 5;