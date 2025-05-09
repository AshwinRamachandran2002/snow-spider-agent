SELECT
    "collection_id"                                AS "CollectionID",
    "PatientID",
    "PatientSex",
    "PatientAge",
    "StudyInstanceUID",
    "StudyDescription",
    "StudyDate",
    "SeriesInstanceUID",
    "SeriesDescription",
    "SeriesDate",
    /* append a wildcard so the returned path can be used to fetch every
       object (all instances) that belongs to the series                 */
    CONCAT("series_aws_url", '*')                 AS "SeriesAWSURL",
    /* convert summed bytes to MB, round to two decimals                 */
    ROUND(SUM("instance_size")/1000000, 2)        AS "SeriesSizeMB"
FROM  IDC.IDC_V17.DICOM_ALL
WHERE "PatientSex"      = 'M'                           -- male patients
  AND "BodyPartExamined" = 'MEDIASTINUM'                -- required body part
  AND "StudyDate"       > '2014-09-01'                  -- study date filter
  /* keep only ages whose numeric part is exactly 18 and unit is years   */
  AND TO_NUMBER( REGEXP_SUBSTR("PatientAge", '\\d+') ) = 18
  AND UPPER(RIGHT("PatientAge",1)) = 'Y'
GROUP BY
      "collection_id",
      "PatientID",
      "PatientSex",
      "PatientAge",
      "StudyInstanceUID",
      "StudyDescription",
      "StudyDate",
      "SeriesInstanceUID",
      "SeriesDescription",
      "SeriesDate",
      CONCAT("series_aws_url", '*')
ORDER BY
      "StudyDate"        ASC,
      "SeriesInstanceUID";