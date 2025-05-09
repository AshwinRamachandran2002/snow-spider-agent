WITH eligible_wins AS (
    SELECT
        bs."BowlerID"            AS bowler_id,
        bs."MatchID"             AS match_number,
        bs."GameNumber"          AS game_number,
        bs."HandiCapScore"       AS handicap_score,
        t."TourneyDate"          AS tournament_date,
        t."TourneyLocation"      AS location
    FROM "Bowler_Scores"   AS bs
    JOIN "Tourney_Matches" AS tm USING ("MatchID")
    JOIN "Tournaments"     AS t  USING ("TourneyID")
    WHERE bs."WonGame" = 1
      AND bs."HandiCapScore" <= 190
      AND t."TourneyLocation" IN ('Thunderbird Lanes',
                                  'Totem Lanes',
                                  'Bolero Lanes')
),
qualifying_bowlers AS (
    SELECT bowler_id
    FROM   eligible_wins
    GROUP  BY bowler_id
    HAVING COUNT(DISTINCT location) = 3
)
SELECT
    qb.bowler_id,
    b."BowlerFirstName" AS first_name,
    b."BowlerLastName"  AS last_name,
    ew.match_number,
    ew.game_number,
    ew.handicap_score,
    ew.tournament_date,
    ew.location
FROM   eligible_wins      AS ew
JOIN   qualifying_bowlers AS qb ON ew.bowler_id = qb.bowler_id
JOIN   "Bowlers"          AS b  ON b."BowlerID" = ew.bowler_id
ORDER  BY qb.bowler_id,
          ew.location,
          ew.match_number,
          ew.game_number;