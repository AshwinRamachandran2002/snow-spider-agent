SELECT cleaned_page_path AS Page_Path,
       total_page_views AS Total_Page_Views
FROM (
  SELECT cleaned_page_path,
         COUNT(*) AS total_page_views,
         ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS rn
  FROM (
    SELECT
      REGEXP_REPLACE(
        REGEXP_EXTRACT(
          (SELECT ep.value.string_value
           FROM UNNEST(event_params) AS ep
           WHERE ep.key = 'page_location' AND ep.value.string_value IS NOT NULL),
          r'https?://[^/]+(/.*|$)'
        ),
        r'/+','/'
      ) AS cleaned_page_path
    FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_202012*`
    WHERE
      event_name = 'page_view' AND
      REGEXP_EXTRACT(
        (SELECT ep.value.string_value
         FROM UNNEST(event_params) AS ep
         WHERE ep.key = 'page_location' AND ep.value.string_value IS NOT NULL),
        r'https?://([^/]+)'
      ) = 'shop.googlemerchandisestore.com'
  )
  WHERE cleaned_page_path IS NOT NULL
  GROUP BY cleaned_page_path
)
WHERE rn = 2