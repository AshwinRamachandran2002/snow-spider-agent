SELECT 
  TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) AS "Date",
  ROUND(
    CASE 
      WHEN "temp" >= 9999 THEN NULL 
      ELSE (("temp" - 32) * 5 / 9) 
    END, 4
  ) AS "Temperature_Celsius",
  ROUND(
    CASE 
      WHEN "prcp" >= 99.99 THEN NULL 
      ELSE ("prcp" * 2.54) 
    END, 4
  ) AS "Precipitation_cm",
  ROUND(
    CASE 
      WHEN TRY_TO_NUMERIC("wdsp") >= 999 THEN NULL 
      ELSE (TRY_TO_NUMERIC("wdsp") * 0.514444) 
    END, 4
  ) AS "Wind_Speed_mps",
  -- Moving averages over a window of 8 days
  ROUND(
    AVG(
      CASE 
        WHEN "temp" >= 9999 THEN NULL 
        ELSE (("temp" - 32) * 5 / 9) 
      END
    ) OVER (
      ORDER BY TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) 
      ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
    ), 4
  ) AS "Temperature_MA8_Celsius",
  ROUND(
    AVG(
      CASE 
        WHEN "prcp" >= 99.99 THEN NULL 
        ELSE ("prcp" * 2.54) 
      END
    ) OVER (
      ORDER BY TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) 
      ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
    ), 4
  ) AS "Precipitation_MA8_cm",
  ROUND(
    AVG(
      CASE 
        WHEN TRY_TO_NUMERIC("wdsp") >= 999 THEN NULL 
        ELSE (TRY_TO_NUMERIC("wdsp") * 0.514444) 
      END
    ) OVER (
      ORDER BY TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) 
      ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
    ), 4
  ) AS "Wind_Speed_MA8_mps",
  -- Differences between the current moving average and the one from 8 days prior
  ROUND(
    (
      AVG(
        CASE 
          WHEN "temp" >= 9999 THEN NULL 
          ELSE (("temp" - 32) * 5 / 9) 
        END
      ) OVER (
        ORDER BY TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) 
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
      ) - 
      AVG(
        CASE 
          WHEN "temp" >= 9999 THEN NULL 
          ELSE (("temp" - 32) * 5 / 9) 
        END
      ) OVER (
        ORDER BY TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) 
        ROWS BETWEEN 15 PRECEDING AND 8 PRECEDING
      )
    ), 4
  ) AS "Temperature_Difference_Celsius",
  ROUND(
    (
      AVG(
        CASE 
          WHEN "prcp" >= 99.99 THEN NULL 
          ELSE ("prcp" * 2.54) 
        END
      ) OVER (
        ORDER BY TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) 
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
      ) - 
      AVG(
        CASE 
          WHEN "prcp" >= 99.99 THEN NULL 
          ELSE ("prcp" * 2.54) 
        END
      ) OVER (
        ORDER BY TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) 
        ROWS BETWEEN 15 PRECEDING AND 8 PRECEDING
      )
    ), 4
  ) AS "Precipitation_Difference_cm",
  ROUND(
    (
      AVG(
        CASE 
          WHEN TRY_TO_NUMERIC("wdsp") >= 999 THEN NULL 
          ELSE (TRY_TO_NUMERIC("wdsp") * 0.514444) 
        END
      ) OVER (
        ORDER BY TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) 
        ROWS BETWEEN 7 PRECEDING AND CURRENT ROW
      ) - 
      AVG(
        CASE 
          WHEN TRY_TO_NUMERIC("wdsp") >= 999 THEN NULL 
          ELSE (TRY_TO_NUMERIC("wdsp") * 0.514444) 
        END
      ) OVER (
        ORDER BY TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) 
        ROWS BETWEEN 15 PRECEDING AND 8 PRECEDING
      )
    ), 4
  ) AS "Wind_Speed_Difference_mps"
FROM "NOAA_DATA"."NOAA_GSOD"."GSOD2019" AS gsod
WHERE "stn" IN (
  SELECT "usaf"
  FROM "NOAA_DATA"."NOAA_GSOD"."STATIONS"
  WHERE "name" ILIKE '%ROCHESTER%'
    AND "state" = 'NY'
)
  AND TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) >= '2019-01-09'
  AND TO_DATE("year" || '-' || LPAD("mo", 2, '0') || '-' || LPAD("da", 2, '0')) <= '2019-03-31'
ORDER BY "Date" ASC;