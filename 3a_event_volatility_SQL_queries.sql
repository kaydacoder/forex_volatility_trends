-- creating a database to store the tables.
CREATE DATABASE volatility_trends;

-- use 'volatility_trends' database.
USE volatility_trends;

-- creating table to store key economic events.
CREATE TABLE major_events (
date_of_event DATE NOT NULL,
event_name VARCHAR(255)  NOT NULL,
location VARCHAR(255) NOT NULL
);

-- adding 'economic_calendar.csv' to 'major_events' table.
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.3/Uploads/economic_calendar.csv"
INTO TABLE volatility_trends.major_events
FIELDS TERMINATED BY ','
ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- checking data loaded into table. 
SELECT * FROM major_events;

-- creating table to store EUR/USD prices.
CREATE TABLE forex_info (
date_of_price DATE NOT NULL,
price DOUBLE NOT NULL,
price_change VARCHAR(255)
);

-- adding 'forex_data.csv' to 'forex_info' table.
LOAD DATA INFILE "C:/ProgramData/MySQL/MySQL Server 8.3/Uploads/forex_data.csv"
INTO TABLE volatility_trends.forex_info
FIELDS TERMINATED BY ','
ENCLOSED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- changing price_change data type from VARCHAR to DOUBLE.
UPDATE forex_info
SET price_change = CAST(price_change AS DOUBLE);   


-- checking data loaded into table. 
SELECT * FROM forex_info;


-- Matching economic events with corresponding volatility data.
SELECT major_events.date_of_event, major_events.event_name, major_events.location,	forex_info.price, 
CAST(forex_info.price_change AS DECIMAL(5,4))*100 AS 'price change %'
FROM major_events
LEFT JOIN forex_info
ON major_events.date_of_event = forex_info.date_of_price;

-- Identify changes in volatility before, during, and after economic events. 
CREATE TABLE price_before_event AS
SELECT major_events.date_of_event, major_events.event_name, 
forex_info.price AS day_before_price
FROM major_events
LEFT JOIN forex_info
ON ADDDATE(major_events.date_of_event, INTERVAL -1 day) = forex_info.date_of_price;

SELECT * FROM volatility_trends.event_before_during_after;


CREATE TABLE price_before_event_and_during AS
SELECT price_before_event.date_of_event,price_before_event.event_name, 
price_before_event.day_before_price , forex_info.price AS day_price
FROM price_before_event
LEFT JOIN forex_info
ON price_before_event.date_of_event = forex_info.date_of_price;

-- check how event affected prices before, during and after. 
CREATE TABLE event_before_during_after AS
SELECT price_before_event_and_during.date_of_event, price_before_event_and_during.event_name,
price_before_event_and_during.day_before_price, price_before_event_and_during.day_price,
forex_info.price AS day_after_price
FROM priceevent_prices_affect_before_event_and_during
LEFT JOIN forex_info
ON ADDDATE(price_before_event_and_during.date_of_event, INTERVAL 1 day) = forex_info.date_of_price;

-- Compare the volatility changes during different types of economic events.
CREATE TABLE event_prices_affect AS
SELECT major_events.event_name, MIN(major_events.location) AS location, 
CAST(AVG(forex_info.price_change) AS DECIMAL(5,4))*100 AS '% changes', CAST(STD(forex_info.price_change) AS DECIMAL(5,4))*100 AS 'volatility_range %'
FROM major_events
LEFT JOIN forex_info
ON major_events.date_of_event = forex_info.date_of_price
GROUP BY major_events.event_name
ORDER BY '% changes' DESC;


-- Create a visualisation for the relationship between events and volatility.
-- Summarise key insights and trends.
-- - top 10 events with highest avg. volatility ranges and where in the world they are located.
-- - top 10 events with highest avg. volatility ranges and what their price change % are.
SELECT *
FROM event_prices_affect;

-- - What is the distribution for these events in terms of location (US & EUR)?
SELECT location, COUNT(location),
COUNT(location)/(SELECT COUNT(location) FROM major_events) AS 'Distribution of Events (%)'
FROM major_events
GROUP BY location;

SELECT COUNT(location)
FROM major_events;
-- had to correct previous query the showed 3 rows - prior to correction.
UPDATE event_prices_affect
SET location = 'US'
WHERE location LIKE '%US%';

-- Draw conclusions on how specific events influence EUR/USD volatility. 
/* 
Economic events that take place within the US are more likely to have a greater higher amount of volatility.
Events with the highest amount of volatility generally resulted in negative changes in price.
*/

