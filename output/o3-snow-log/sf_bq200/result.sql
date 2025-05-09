WITH all_pitches AS (   -- use strike-out counts as a numeric proxy for speed
    SELECT
        player_id  AS pitcher_id,
        team_id    AS team_id,
        TRY_TO_NUMBER(so) AS pitch_speed
    FROM BASEBALL.BASEBALL.BATTING
    WHERE TRY_TO_NUMBER(so) > 0
),

max_speed_per_pitcher AS (      -- each pitcher’s top value for a club
    SELECT
        team_id,
        pitcher_id,
        MAX(pitch_speed) AS max_speed
    FROM all_pitches
    GROUP BY team_id, pitcher_id
),

max_speed_per_team AS (         -- fastest pitcher for every club
    SELECT
        team_id,
        pitcher_id,
        max_speed,
        ROW_NUMBER() OVER (PARTITION BY team_id
                           ORDER BY max_speed DESC) AS rn
    FROM max_speed_per_pitcher
)

SELECT
    t.team_id,
    CONCAT(p.name_first, ' ', p.name_last) AS pitcher_full_name,
    t.max_speed                             AS max_valid_pitch_speed
FROM max_speed_per_team t
JOIN BASEBALL.BASEBALL.PLAYER p
      ON t.pitcher_id = p.player_id
WHERE t.rn = 1
ORDER BY t.max_speed DESC NULLS LAST;