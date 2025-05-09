SELECT
       "PatientID",
       "PatientSex",
       "PatientAge",
       "StudyInstanceUID",
       "StudyDate",
       "SeriesInstanceUID",
       "SeriesDescription",
       "BodyPartExamined",
       MIN("aws_url")                            AS "series_aws_url",
       ROUND(SUM("instance_size") / 1000000, 2)  AS "series_size_MB"
FROM   IDC.IDC_V17.DICOM_ALL
WHERE  "PatientSex" = 'M'
  AND  SUBSTR("PatientAge", 1, 3) = '018'              -- exactly 18 years old
  AND  "BodyPartExamined" = 'MEDIASTINUM'
  AND  "StudyDate" > '2014-09-01'                      -- strictly after 2014-09-01
GROUP BY
       "PatientID",
       "PatientSex",
       "PatientAge",
       "StudyInstanceUID",
       "StudyDate",
       "SeriesInstanceUID",
       "SeriesDescription",
       "BodyPartExamined"
ORDER BY
       "PatientID",
       "StudyDate",
       "SeriesInstanceUID";