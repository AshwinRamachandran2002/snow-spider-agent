-- =========================================================================
--  NCAA MEN’S TOURNAMENT (2014‑present)  ►  TEAM & OPPONENT PACE / EFFICIENCY
--  • Combines historic tournament games (2014+) and the dedicated 2018 table
--  • Adds pace‑ and efficiency‑related features for BOTH teams
--  • Calculates opponent‑minus‑team differentials to simplify modelling
-- =========================================================================
WITH games_union AS (        -- 1.  All tournament results, one row PER TEAM
    -- --- Historic file ----------------------------------------------------
    SELECT  season,
            win_seed               AS seed,
            win_school_ncaa        AS school_ncaa,
            lose_seed              AS opponent_seed,
            lose_school_ncaa       AS opponent_school_ncaa,
            'win'                  AS label
    FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
    WHERE season >= 2014

    UNION ALL
    SELECT  season,
            lose_seed              AS seed,
            lose_school_ncaa       AS school_ncaa,
            win_seed               AS opponent_seed,
            win_school_ncaa        AS opponent_school_ncaa,
            'loss'                 AS label
    FROM  `data-to-insights.ncaa.mbb_historical_tournament_games`
    WHERE season >= 2014

    -- --- Stand‑alone 2018 file -------------------------------------------
    UNION ALL
    SELECT  season,
            seed,
            school_ncaa,
            opponent_seed,
            opponent_school_ncaa,
            label
    FROM  `data-to-insights.ncaa.2018_tournament_results`
    WHERE season >= 2014
),

cleaned_games AS (           -- 2.  Small text clean‑up to improve joins
    SELECT  season,
            label,
            SAFE_CAST(seed           AS INT64)  AS seed,
            school_ncaa,
            SAFE_CAST(opponent_seed  AS INT64)  AS opponent_seed,
            opponent_school_ncaa,
            LOWER(REGEXP_REPLACE(school_ncaa         , r'[^a-z0-9]', '')) AS school_clean,
            LOWER(REGEXP_REPLACE(opponent_school_ncaa, r'[^a-z0-9]', '')) AS opp_school_clean
    FROM games_union
),

team_metrics AS (            -- 3.  Pace / efficiency features for every team
    SELECT  season,
            team,
            poss_40min,
            pace_rating,
            pace_rank,
            pts_100poss,
            efficiency_rating,
            efficiency_rank,
            LOWER(REGEXP_REPLACE(team, r'[^a-z0-9]', '')) AS team_clean
    FROM `data-to-insights.ncaa.feature_engineering`
)

-- 4.  Final assembled data set
SELECT
    g.season,
    g.label,
    g.seed,
    g.school_ncaa,
    g.opponent_seed,
    g.opponent_school_ncaa,

    -- ----------  team metrics ---------------------------------------------
    t.pace_rank           ,
    t.poss_40min          ,
    t.pace_rating         ,
    t.efficiency_rank     ,
    t.pts_100poss         ,
    t.efficiency_rating   ,

    -- ----------  opponent metrics -----------------------------------------
    o.pace_rank           AS opp_pace_rank         ,
    o.poss_40min          AS opp_poss_40min        ,
    o.pace_rating         AS opp_pace_rating       ,
    o.efficiency_rank     AS opp_efficiency_rank   ,
    o.pts_100poss         AS opp_pts_100poss       ,
    o.efficiency_rating   AS opp_efficiency_rating ,

    -- ----------  simple opponent‑minus‑team differentials -----------------
    (o.pace_rank         - t.pace_rank        ) AS pace_rank_diff,
    (o.poss_40min        - t.poss_40min       ) AS poss_40min_diff,
    (o.pace_rating       - t.pace_rating      ) AS pace_rating_diff,
    (o.efficiency_rank   - t.efficiency_rank  ) AS eff_rank_diff,
    (o.pts_100poss       - t.pts_100poss      ) AS pts_100poss_diff,
    (o.efficiency_rating - t.efficiency_rating) AS efficiency_rating_diff

FROM   cleaned_games  AS g
LEFT JOIN team_metrics AS t
       ON t.season     = g.season
      AND t.team_clean = g.school_clean
LEFT JOIN team_metrics AS o
       ON o.season     = g.season
      AND o.team_clean = g.opp_school_clean
ORDER BY g.season, g.school_ncaa, g.label DESC;