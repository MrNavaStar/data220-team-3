
-- A3: In each month, on how many days did EDM-A have at least 10 cm of snow on the ground?
-- Show: month (the first 7 characters of date, e.g. 2026-01) and deep_snow_days,
--       the earliest month first
-- Table: weather_daily (the column snow_ground_cm exists after A2)
-- Uses: substr(date, 1, 7), COUNT(*), WHERE ... AND ..., GROUP BY, ORDER BY (Week 9)

SELECT
    substr(date, 1, 7) AS month,
    COUNT(*) AS deep_snow_days
FROM weather_daily
WHERE station_code = 'EDM-A'
  AND snow_ground_cm >= 10
GROUP BY substr(date, 1, 7)
ORDER BY month ASC;
