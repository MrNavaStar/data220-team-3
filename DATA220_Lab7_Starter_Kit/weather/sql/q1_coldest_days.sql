
-- W3, question 1: Which five days were coldest at station EDM-A?
-- Show: date and min_temp_c, the coldest day first.
-- Table: weather_daily
-- Uses: SELECT, FROM, WHERE, ORDER BY, LIMIT

SELECT date, min_temp_c
FROM weather_daily
WHERE station_code = 'EDM-A'
ORDER BY min_temp_c ASC
LIMIT 5;
