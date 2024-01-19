-- Total Cases vs Total Deaths

Select country, date, total_cases, new_cases, total_deaths, population
From CovidDeaths
Where continent is not null 
order by country, date



-- Shows likelihood of dying if you contract covid in your country

Select country, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidDeaths
Where country = 'Bangladesh'
and continent is not null 
order by 1,2

-- Total Cases vs Population
-- The percentage of population infected with Covid

Select country, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From CovidDeaths

order by 1,2







--Finding the highest death rates by country
SELECT country, population,  MAX(total_deaths) AS deaths, Max(total_deaths/population) AS mortality
FROM coviddeaths
WHERE continent IS NOT null
GROUP  BY  country, population
ORDER BY mortality DESC;






-- Finding the highest infection rates by country
SELECT country, population,  MAX(total_cases) AS cases, Max(total_cases/population) AS Infection_Rate
FROM coviddeaths
WHERE continent IS NOT null AND total_cases IS NOT null
GROUP  BY country, population
ORDER BY Infection_Rate DESC;

/* Finding the highest infection rates by continent. I had to use a (where continent is null) since the continents are actually listed in the country column while the corresponding continent is written null so it was the only way I could extract it */
SELECT country,  MAX(cast(total_cases AS int)) AS cases
FROM coviddeaths
WHERE continent IS null 
GROUP  BY  country
ORDER BY cases DESC;

--Finding the highest death rates by Continent
SELECT country,  MAX(cast(total_deaths AS int)) AS deaths
FROM coviddeaths
WHERE continent IS null 
GROUP  BY  country
ORDER BY deaths DESC;






-- Looking at the entire world.

SELECT  date,  sum(new_cases) AS totalcases, sum(new_deaths) AS totaldeaths, (SUM(total_cases)*100/Sum(total_deaths)) AS Mortality
FROM coviddeaths
WHERE continent IS NOT null 
GROUP  BY  date 
ORDER BY date DESC;

-- contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc


/*Getting a rolling vaccinated count using a sum window function
*/

SELECT covidA.continent, covidA.country, covidA.date, population, covidB.new_vaccinations,
	SUM(covidB.new_vaccinations) over (Partition by covidA.country ORDER BY covidA.country, covidA.date) 
	AS RollingPopulation_Vaccinated
	FROM coviddeaths covidA
	LEFT JOIN covidvax covidB
	on covidA.date = covidB.date
	AND covidA.country = covidB.country
	WHERE covidA.continent IS NOT NULL
	ORDER BY covidA.country
/* Vaccine Rates By Country. I had to use CTE, Window Function and join the deaths and vaccines tables to get the percentage from the window function */
WITH vaxrate_ (continent, country, date, population, new_vaccinations, RollingPopulation_Vaccinated_)
AS (
	SELECT covidA.continent, covidA.country, covidA.date, population, covidB.new_vaccinations,
	SUM(covidB.new_vaccinations) over (Partition by covidA.country ORDER BY covidA.country, covidA.date) 
	AS RollingPopulation_Vaccinated
	FROM coviddeaths covidA
	LEFT JOIN covidvax covidB
	on covidA.date = covidB.date
	AND covidA.country = covidB.country
	WHERE covidA.continent IS NOT NULL
	ORDER BY covidA.country
)
SELECT *, RollingPopulation_Vaccinated_*100/population as percent_vaccinated
FROM vaxrate_





----temporary table to use
DROP TABLE IF EXISTS vaxrates;
CREATE TEMPORARY TABLE  vaxrates
(continent text, 
 Country text,
 "Date" DATE,
 Population numeric,
 new_vaccinations numeric,
 RollingPopulation_Vaccinated numeric,
 vaxrate numeric
);

WITH vaxrate_ (continent, country, date, population, new_vaccinations, RollingPopulation_Vaccinated_)
AS (


	SELECT covidA.continent, covidA.country, covidA.date, population, covidB.new_vaccinations,
	SUM(covidB.new_vaccinations) over (Partition by covidA.country ORDER BY covidA.country, covidA.date) 
	AS RollingPopulation_Vaccinated
	FROM coviddeaths covidA
	LEFT JOIN covidvax covidB
	on covidA.date = covidB.date
	AND covidA.country = covidB.country
	WHERE covidA.continent IS NOT NULL
	ORDER BY covidA.country
)
INSERT INTO vaxrates
SELECT *, RollingPopulation_Vaccinated_*100/population as percent_vaccinated
FROM vaxrate_

;
-- Joinin the vaxrate with the death stats
create view vax_effect as(

SELECT vaxrates.country, vaxrates."Date" , vaxrate, new_deaths, new_cases, 
(new_deaths/ coviddeaths.population) as death_percentage,
(new_cases/ coviddeaths.population) as case_percentage
FROM vaxrates
INNER JOIN coviddeaths ON vaxrates.country = coviddeaths.country
                       AND vaxrates."Date" = coviddeaths.date


)

select * from vax_effect


