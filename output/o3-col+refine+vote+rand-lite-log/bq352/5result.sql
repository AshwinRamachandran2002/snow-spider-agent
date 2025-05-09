/* -------------------------------------------------------------
   Average 2018 prenatal-weeks for Wisconsin counties whose
   ZIP/ZCTA areas showed > 5 % 45–59-minute commute share (2017)
   ------------------------------------------------------------- */
WITH
/* 1.  Wisconsin ZIP/ZCTA prefixes whose 45–59-minute commute
        share exceeded 5 % in 2017. */
high_commute_zip3 AS (
  SELECT DISTINCT LEFT(geo_id,3) AS zip3
  FROM `bigquery-public-data.census_bureau_acs.zcta5_2017_5yr`
  WHERE LEFT(geo_id,2) IN ('53','54')                          -- Wisconsin
    AND SAFE_DIVIDE(commute_45_59_mins , employed_pop) > 0.05  -- > 5 %
),

/* 2.  Hand-built bridge from ZIP-3 prefixes to Wisconsin counties.
        (One prefix can touch several counties.)               */
zip3_to_county AS (
  SELECT *
  FROM UNNEST([
    STRUCT('530' AS zip3,'Waukesha County, WI'  AS county),
    ('530','Washington County, WI'),
    ('530','Ozaukee County, WI'),

    ('531','Kenosha County, WI'),
    ('531','Racine County, WI'),
    ('531','Walworth County, WI'),

    ('532','Milwaukee County, WI'),
    ('534','Racine County, WI'),

    ('535','Dane County, WI'),
    ('535','Green County, WI'),
    ('535','Iowa County, WI'),
    ('537','Dane County, WI'),

    ('538','Grant County, WI'),

    ('539','Columbia County, WI'),
    ('539','Sauk County, WI'),
    ('539','Dodge County, WI'),

    ('540','St. Croix County, WI'),
    ('540','Pierce County, WI'),
    ('540','Polk County, WI'),

    ('541','Brown County, WI'),
    ('541','Oconto County, WI'),
    ('541','Outagamie County, WI'),
    ('541','Shawano County, WI'),

    ('542','Kewaunee County, WI'),
    ('542','Door County, WI'),
    ('542','Manitowoc County, WI'),

    ('544','Marathon County, WI'),
    ('544','Portage County, WI'),
    ('544','Wood County, WI'),

    ('545','Vilas County, WI'),
    ('545','Oneida County, WI'),
    ('545','Iron County, WI'),

    ('546','La Crosse County, WI'),
    ('546','Vernon County, WI'),
    ('546','Jackson County, WI'),
    ('546','Trempealeau County, WI'),
    ('546','Monroe County, WI'),

    ('547','Eau Claire County, WI'),
    ('547','Chippewa County, WI'),
    ('547','Dunn County, WI'),

    ('548','Douglas County, WI'),
    ('548','Barron County, WI'),
    ('548','Burnett County, WI'),
    ('548','Bayfield County, WI'),
    ('548','Sawyer County, WI'),
    ('548','Washburn County, WI'),

    ('549','Outagamie County, WI'),
    ('549','Winnebago County, WI'),
    ('549','Fond du Lac County, WI'),
    ('549','Calumet County, WI'),
    ('549','Green Lake County, WI'),
    ('549','Waupaca County, WI')
  ]) 
),

/* 3. Keep only counties whose ZIP-3 prefix is on the
      high-commute list. */
target_counties AS (
  SELECT DISTINCT county
  FROM zip3_to_county
  WHERE zip3 IN (SELECT zip3 FROM high_commute_zip3)
)

/* 4. 2018 average prenatal-weeks for those counties. */
SELECT
  n.County_of_Residence                    AS county,
  ROUND(AVG(n.Ave_Number_of_Prenatal_Wks),4) AS avg_prenatal_weeks_2018
FROM `bigquery-public-data.sdoh_cdc_wonder_natality.county_natality_by_maternal_morbidity` n
JOIN target_counties t
  ON n.County_of_Residence = t.county
WHERE EXTRACT(YEAR FROM n.Year) = 2018
GROUP BY county
ORDER BY county;