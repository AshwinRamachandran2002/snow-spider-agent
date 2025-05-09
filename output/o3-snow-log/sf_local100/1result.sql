/*-------------------------------------------------------------
   How many actors have a “Shahrukh number” of 2 ?
   – Shahrukh-number-1  : shared a film with Shahrukh Khan
   – Shahrukh-number-2  : shared a film with any SN-1 actor,
                          but never with Shahrukh Khan himself
--------------------------------------------------------------*/
WITH
/* 1.  Shahrukh Khan’s unique PID(s)                                        */
"SHAHRUKH" AS (
    SELECT DISTINCT TRIM("PID") AS "PID"
    FROM   DB_IMDB.DB_IMDB.PERSON
    WHERE  TRIM("Name") ILIKE '%Shah%Rukh%Khan%'        -- catches “Shah Rukh Khan” / “Shahrukh Khan”
),
/* 2.  Every movie in which Shahrukh Khan acted                              */
"SHAHRUKH_MOVIES" AS (
    SELECT DISTINCT TRIM("MID") AS "MID"
    FROM   DB_IMDB.DB_IMDB.M_CAST
    WHERE  TRIM("PID") IN (SELECT "PID" FROM "SHAHRUKH")
),
/* 3.  Actors with Shahrukh-number = 1 (direct co-stars)                     */
"SN1_ACTORS" AS (
    SELECT DISTINCT TRIM("PID") AS "PID"
    FROM   DB_IMDB.DB_IMDB.M_CAST
    WHERE  TRIM("MID") IN (SELECT "MID" FROM "SHAHRUKH_MOVIES")
      AND  TRIM("PID") NOT IN (SELECT "PID" FROM "SHAHRUKH")
),
/* 4.  All movies that feature at least one SN-1 actor                       */
"MOVIES_WITH_SN1" AS (
    SELECT DISTINCT TRIM("MID") AS "MID"
    FROM   DB_IMDB.DB_IMDB.M_CAST
    WHERE  TRIM("PID") IN (SELECT "PID" FROM "SN1_ACTORS")
),
/* 5.  Actors whose Shahrukh-number is exactly 2                             */
"SN2_ACTORS" AS (
    SELECT DISTINCT TRIM("PID") AS "PID"
    FROM   DB_IMDB.DB_IMDB.M_CAST
    WHERE  TRIM("MID") IN (SELECT "MID" FROM "MOVIES_WITH_SN1")
      AND  TRIM("PID") NOT IN (SELECT "PID" FROM "SHAHRUKH")     -- not Shahrukh
      AND  TRIM("PID") NOT IN (SELECT "PID" FROM "SN1_ACTORS")   -- not SN-1
)
/* 6.  Final answer                                                          */
SELECT COUNT(*) AS "NUM_SHAHRUKH_NUMBER_2_ACTORS"
FROM   "SN2_ACTORS";