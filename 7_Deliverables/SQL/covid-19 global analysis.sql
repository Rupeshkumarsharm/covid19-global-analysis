CREATE TABLE covid_stats (
    iso_code VARCHAR(10),
    continent VARCHAR(50),
    location VARCHAR(100),
    date DATE,
    total_cases BIGINT,
    new_cases BIGINT,
    total_deaths BIGINT,
    new_deaths BIGINT,
    total_vaccinations BIGINT,
    new_vaccinations BIGINT,
    PRIMARY KEY (iso_code, date)
);

COPY covid_stats(iso_code, continent, location, date, total_cases, new_cases, total_deaths, new_deaths, total_vaccinations, new_vaccinations)
FROM 'F:/Projects/2_COVID-19 Global Analysis/2_Cleaned Data/owid-covid-cleaned-2.csv'
DELIMITER ','
CSV HEADER;

--Key SQL Queries for Dashboard Insights--
--a) Total cases & deaths globally by date (time trend)--
SELECT
  date,
  SUM(new_cases) AS global_new_cases,
  SUM(new_deaths) AS global_new_deaths
FROM
  covid_stats
WHERE
  continent IS NOT NULL
  AND location NOT IN (
    'World', 'Asia', 'Europe', 'Africa', 'North America', 'South America', 'Oceania',
    'European Union (27)', 'High-income countries', 'Upper-middle-income countries',
    'Lower-middle-income countries', 'Low-income countries'
  )
GROUP BY
  date
ORDER BY
  date;



--Top 10 countries by total cases (latest date)--
WITH country_latest AS (
  SELECT 
    location,
    MAX(date) AS latest_date
  FROM 
    covid_stats
  WHERE 
    total_cases IS NOT NULL
    AND location NOT IN (
      'World', 'Africa', 'Asia', 'Europe', 'European Union (27)', 
      'European Union', 'North America', 'South America', 'Oceania',
      'High-income countries', 'Upper-middle-income countries',
      'Lower-middle-income countries', 'Low-income countries', 'Unknown'
    )
  GROUP BY 
    location
)

SELECT 
  cs.location,
  cs.total_cases,
  cs.total_deaths
FROM 
  covid_stats cs
  JOIN country_latest cl 
    ON cs.location = cl.location AND cs.date = cl.latest_date
ORDER BY 
  cs.total_cases DESC
LIMIT 10;



--Vaccination progress per continent--

SELECT
  continent,
  SUM(max_total_vax) AS total_vaccinations
FROM (
  SELECT
    location,
    continent,
    MAX(total_vaccinations) AS max_total_vax
  FROM
    covid_stats
  WHERE
    continent IS NOT NULL
    AND location NOT IN ('World', 'Asia', 'Europe', 'Africa', 'North America', 'South America', 'Oceania',
      'European Union (27)', 'High-income countries', 'Upper-middle-income countries',
      'Lower-middle-income countries', 'Low-income countries')
  GROUP BY
    location, continent
) AS sub
GROUP BY continent;




--Mortality rate by country (latest date)--

WITH latest_per_location AS (
    SELECT location, MAX(date) AS max_date
    FROM covid_stats
    GROUP BY location
)
SELECT c.location,
       c.total_deaths,
       c.total_cases,
       CASE WHEN c.total_cases > 0 THEN ROUND((c.total_deaths::DECIMAL / c.total_cases) * 100, 2) ELSE 0 END AS mortality_rate_percentage
FROM covid_stats c
JOIN latest_per_location lpl
  ON c.location = lpl.location AND c.date = lpl.max_date
ORDER BY mortality_rate_percentage DESC
LIMIT 10;

--Mortality rate trend per country over time yearly--
SELECT
    location,
    EXTRACT(YEAR FROM date) AS year,
    MAX(total_deaths) AS max_total_deaths,
    MAX(total_cases) AS max_total_cases,
    CASE 
      WHEN MAX(total_cases) > 0 THEN ROUND((MAX(total_deaths)::DECIMAL / MAX(total_cases)) * 100, 2)
      ELSE 0
    END AS mortality_rate_percentage
FROM covid_stats
GROUP BY location, year
ORDER BY location, year;

--Global mortality rate yearly trend--
SELECT
    EXTRACT(YEAR FROM date) AS year,
    MAX(total_deaths) AS max_total_deaths,
    MAX(total_cases) AS max_total_cases,
    CASE 
      WHEN MAX(total_cases) > 0 THEN ROUND((MAX(total_deaths)::DECIMAL / MAX(total_cases)) * 100, 2)
      ELSE 0
    END AS mortality_rate_percentage
FROM covid_stats
GROUP BY year
ORDER BY year;

--Global daily new cases--
SELECT date, SUM(new_cases) AS global_new_cases
FROM covid_stats
GROUP BY date
ORDER BY date;

--Map with total cases by country--
WITH latest_per_country AS (
    SELECT
        location,
        MAX(date) AS latest_date_with_cases
    FROM covid_stats
    WHERE total_cases > 0
    GROUP BY location
)
SELECT
    c.location,
    c.total_cases
FROM covid_stats c
JOIN latest_per_country lpc
  ON c.location = lpc.location AND c.date = lpc.latest_date_with_cases
ORDER BY c.total_cases DESC;

--Vaccinations over time--
SELECT
  date,
  SUM(new_vaccinations) AS global_daily_new_vaccinations
FROM
  covid_stats
WHERE
  continent IS NOT NULL
  AND location NOT IN (
    'World', 'Asia', 'Europe', 'Africa', 'North America', 'South America', 'Oceania',
    'European Union (27)', 'High-income countries', 'Upper-middle-income countries',
    'Lower-middle-income countries', 'Low-income countries'
  )
GROUP BY
  date
ORDER BY
  date;

--Global trend line--
SELECT
  date,
  SUM(new_cases) AS global_new_cases
FROM
  covid_stats
WHERE
  continent IS NOT NULL
  AND location NOT IN (
    'World', 'Asia', 'Europe', 'Africa', 'North America', 'South America', 'Oceania',
    'European Union (27)', 'High-income countries', 'Upper-middle-income countries',
    'Lower-middle-income countries', 'Low-income countries'
  )
GROUP BY
  date
ORDER BY
  date;






--Top countries by cases & deaths--
WITH latest_date_per_country AS (
    SELECT
        location,
        MAX(date) AS latest_date
    FROM covid_stats
    WHERE total_cases > 0 OR total_deaths > 0
    GROUP BY location
)
SELECT
    c.location,
    c.total_cases,
    c.total_deaths
FROM covid_stats c
JOIN latest_date_per_country l
  ON c.location = l.location AND c.date = l.latest_date
ORDER BY c.total_cases DESC
LIMIT 10;

--global KPI values--
SELECT
  SUM(max_cases) AS global_total_cases,
  SUM(max_deaths) AS global_total_deaths,
  SUM(max_vax) AS global_total_vaccinations
FROM (
  SELECT
    location,
    MAX(total_cases) AS max_cases,
    MAX(total_deaths) AS max_deaths,
    MAX(total_vaccinations) AS max_vax
  FROM
    covid_stats
  WHERE
    continent IS NOT NULL
    AND location NOT IN (
      'World', 'Asia', 'Europe', 'Africa', 'North America', 'South America', 'Oceania',
      'European Union (27)', 'High-income countries', 'Upper-middle-income countries',
      'Lower-middle-income countries', 'Low-income countries'
    )
  GROUP BY
    location
) AS sub;
