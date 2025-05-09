/*  How much higher is the mean (across age–groups) number of “discharge” deaths 
    than the mean number of “vehicle” deaths among white individuals?            */

SELECT
    avg_discharge,                       -- average deaths whose descriptions contain “discharge”
    avg_vehicle,                         -- average deaths whose descriptions contain “vehicle”
    avg_discharge - avg_vehicle          AS difference_discharge_minus_vehicle
FROM
    /* ------------------------------------------------------------------------
       1)  Compute the average (mean) number of “discharge” deaths per age group
           – white only, with the three unwanted phrases excluded               */
    ( SELECT
          AVG(death_cnt_discharge) AS avg_discharge
      FROM (
          SELECT
              dr."AgeRecode27",
              COUNT(*) AS death_cnt_discharge
          FROM DEATH.DEATH.DEATHRECORDS  dr
          JOIN DEATH.DEATH.ICD10CODE     ic   ON dr."Icd10Code" = ic."Code"
          WHERE dr."RaceRecode3" = 1                         -- White
            AND ic."Description" ILIKE '%discharge%'
            AND ic."Description" NOT ILIKE '%urethral discharge%'
            AND ic."Description" NOT ILIKE '%discharge of firework%'
            AND ic."Description" NOT ILIKE '%legal intervention involving firearm discharge%'
          GROUP BY dr."AgeRecode27"
      )
    ) AS t_discharge,

    /* ------------------------------------------------------------------------
       2)  Compute the average (mean) number of “vehicle” deaths per age group
           – white only                                                         */
    ( SELECT
          AVG(death_cnt_vehicle) AS avg_vehicle
      FROM (
          SELECT
              dr."AgeRecode27",
              COUNT(*) AS death_cnt_vehicle
          FROM DEATH.DEATH.DEATHRECORDS  dr
          JOIN DEATH.DEATH.ICD10CODE     ic   ON dr."Icd10Code" = ic."Code"
          WHERE dr."RaceRecode3" = 1                         -- White
            AND ic."Description" ILIKE '%vehicle%'
          GROUP BY dr."AgeRecode27"
      )
    ) AS t_vehicle;